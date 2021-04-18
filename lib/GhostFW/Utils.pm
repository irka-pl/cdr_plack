package GhostFW::Utils;

use Exporter 'import'; 
our @EXPORT_OK = qw(&resource_from_classname);

sub resource_from_classname {
    my ($class_name) = @_;
    $class_name = s/::([^:]+)$/$1/;
    return lc($class_name);
}
1;