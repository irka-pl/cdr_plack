package GhostFW::API::Resources::Cdr;
use strict;
use warnings;

use parent qw(GhostFW::API::Base);
use Try::Tiny;
use Data::Dumper;
use HTTP::Status qw(:constants);
#todo: check plack middleware to convert on the flight
use JSON;

#validation and preprocessing
#TODO: DateTime::Format::Builder provides more flexible way
use DateTime::Format::Flexible;
use Locale::Currency;
use Ref::Util qw(is_regexpref is_coderef);
#use Clone;

our $config = {
    POST => {
        'ContentType' => ['application/json', 'multipart/form-data'],
        #no requirements about file name
        'Uploads' => ['text/csv'],
    },
    cdr_fields_order => [qw/caller_id recipient call_date end_time duration cost reference currency/],
    #other known column names in the cdr file header, just example 
    cdr_fields_alias_map => {
        'caller_id' => [qw/caller source src/],
        'recipient' => [qw/callee destination dst/],
        'call_date' => [qw/start start_date start_time/],
        'end_time'  => [qw/end end_date/],
        #etc
    },
};

sub POST {
    my($self) = @_;
    $self->logger->debug( Dumper(['uploads', $self->request->uploads ]));
    if( my $uploads = $self->request->uploads ) {
         foreach my $upload_filename (keys %$uploads) {
            my $upload = $uploads->{$upload_filename};
            try {
                my $upload_fh;
                if ( ! open($upload_fh, "<", $upload->tempname) ) {
                    $self->error({
                        code    => HTTP_INTERNAL_SERVER_ERROR,
                        message => "Failed to open ".$upload->tempname.":$!.",
                    });
                }
                my $fields_order;
                my $first_line = <$upload_fh>;
                my $is_header;
                #in the example file the header contains only alphabet and ","
                #we will try to check if there are at least 2 phone numbers, that are at least 2 digits
                #if there are $caller,$callee - we will use default order of data
                (my($caller, $callee)) = $first_line =~/(\d{2,})/g;
                if ($caller && $callee) {
                    #first line is not a header, use default order
                    $is_header = 0;
                    $fields_order = $self->config->cdr_fields_order;
                } else {
                    $is_header = 1;
                    $first_line =~ s/^[\s\n\r\t]+|[\s\n\r\t]+$//g;
                    $fields_order = [map {lc($_)} split(',',$first_line)];
                    my $fields_input = {map{$_ => 1} @{$fields_order}};
                    #check all our fields
                    foreach my $field_name_config (@{$self->config->{cdr_fields_order}}) {
                        #if some of the cdr field we expect is not in the header
                        if(!$fields_input->{$field_name_config}){
                            #then let's check known aliases
                            foreach my $alias (@{$self->config->{cdr_fields_alias_map}->{$field_name_config}}) {
                                #if we found that header contained one of the known alias for the $field_name_config
                                if($fields_input->{$alias}) {
                                    #lets replace the alias to it's original name in the $fields_order taken from the header
                                    $fields_order = [map {($_ eq $alias) ? $field_name_config : $_} @{$fields_order}];
                                }#we replaced alias to its original name
                                else {
                                    $self->error({
                                        code    => HTTP_INTERNAL_SERVER_ERROR,
                                        message => "Incorrect file format. Field '$field_name_config' not found.",
                                    });
                                }
                            }#/we checked all aliases for the field that we didn't find in the header
                        }#/we processed field that wasn't found in the header
                    }#/we checked all cdr fields that we expect and have configured
                }#/we think that first line is a header with column names
                if(!$is_header){
                    seek ( $upload_fh, 0, 0 ); 
                }
                #we can use it later for more easy management, e.g. remove some wrong upload
                #todo: wrap around DataTime
                my $insert_datetime = DateTime->now();
                my @skipped_lines;
                my $line_number = 0;
                while( my $line = <$upload_fh>) {
                    $line_number++;
                    #todo: I'm pretty sure that somewhere there is a package to strip values ;-)
                    $line =~ s/^[\s\n\r\t]+|[\s\n\r\t]+$//g;
                    my $data_row = { insert_datetime => $insert_datetime };
                    @{$data_row}{@{$fields_order}} = split(',', $line);
                    #we put it outside, as caller better knows if it should be cloned or smthing else
                    my ( $errors, $data_row_processed) = $self->validate_data($data_row);
                    #$self->logger->debug(Dumper([$errors, $data_row, $data_row_processed]));
                    if ($errors) {
                        push @skipped_lines, {line => $line, number => $line_number, errors => $errors};
                    } else {
                        #call_date text,
                        #end_time text,
                        #start_date_time text,
                        #end_date_time text,

                        #todo: separate processing to a method too
                        # and we will have draft of the generic method for the line-by-line file processing
                        
                        # We have start_date = 02.04.2021 and end_time 00:10:00 and duration 1800
                        #1. we suppose that end is 02.04.2021 00:10:00
                        my $end_date_time_approx = DateTime::Format::Flexible->parse_datetime(
                            $data_row->{call_date}.' '.$data_row->{end_time},
                            european => 1,
                        );
                        #2. but we get start_date = 01.04.2021 23:40:00, date is incorrect
                        my $start_date_time_approx = $end_date_time_approx->subtract(seconds => $data_row->{duration});
                        #2.1. if we had other data, and call started and ended in the same day, as we supposed:
                       if ($start_date_time_approx->ymd eq $data_row_processed->{call_date}->ymd ) {
                            $data_row->{start_date_time} = $start_date_time_approx;
                            $data_row->{end_date_time} = $end_date_time_approx;
                        } else {
                            #2.2. but really we saw that we shifted
                            #3. so we move end_date to one day forward, it become 03.04.2021 00:10:00
                            $data_row->{end_date_time} = $end_date_time_approx->add(days => 1);
                            #4. and the same adjust start date_time, it will be now 02.04.2021 23:40:00
                            $data_row->{start_date_time} = $start_date_time_approx->add(days => 1);
                        }
                        try {
                            #todo: if we had an unique index on the start_date_time, caller_id(, recipient ?) we could catch here and push it to errors
                            $self->model->db->create_item($data_row);
                        } catch {
                            $self->logger->debug("error insert: $_;");
                            if ( $_ =~ /UNIQUE constraint failed/i){
                                push @skipped_lines, {line => $line, number => $line_number, errors => ['Line is already presented'] };
                            }
                        }
                    }#/we didn't find error for the row and tried to insert it
                }#/process uploaded file line-by-line
                if(@skipped_lines) {
                    $self->response->body(encode_json (\@skipped_lines));
                }
            } catch {
                $self->error({
                    code    => HTTP_INTERNAL_SERVER_ERROR,
                    message => "Failed to process uploaded file: $_.",
                });
            };
        }
    }
    $self->response->status(200);
}


#------aux

#todo: move to separate package. Under Model ? 
#target - avoid double processing for validation and preprocessing.
#save validate results to use in preprocessing
#and avoid multiple config initialization
sub validate_data {
    my ($self, $row, $row_preprocessed) = @_;
    #we expect only simple hash there, raw data, but can think about Storable clone
    #but this is only default, caller can pass his own version
    $row_preprocessed //= {%{$row}};
    my $errors = {};
    my $parse_datetime = sub {
        my($data) = @_;
        my $dt = DateTime::Format::Flexible->parse_datetime(
            $data,
            european => 1,
        );
        #TODO:run once more if european failed? check this.
        return $dt;
    };
    my $parse_currency = sub {
        my($data) = @_;
        if(code2currency($data)){
            return $data;
        }
    };
    #todo: use input::validate
    my $validator_config = {
        caller_id => qr{\d+},
        recipient => qr{\d+},
        call_date => $parse_datetime,
        end_time  => qr{\d{2}:\d{2}:\d{2}},
        duration  => qr{\d+},
        cost      => qr{\d+(?:[\.\,]\d+)},
        reference => qr{[A-Z0-9]{33}},
        currency  => $parse_currency,
    };
    foreach my $field (keys %{$row}) {
        if (my $rule = $validator_config->{$field}) {
            if( is_regexpref( $rule ) ) {
                if ( ! $row->{$field} =~ $rule ) {
                    $errors->{$field} = "Field '$field' didn't match format pattern '$rule'.";
                }
            } elsif ( is_coderef( $rule ) ) {
                my $result = $rule->($row->{$field});
                #$self->logger->debug("processing result: $result;");
                if (!$result) {
                    $errors->{$field} = "Field '$field' didn't pass checking method.";
                } else {
                    $row_preprocessed->{$field} = $result;
                }
            }
        }
    }
    return ( (scalar keys %{$errors} ? $errors : undef), $row_preprocessed );
}

1;