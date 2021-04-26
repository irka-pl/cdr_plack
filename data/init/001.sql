CREATE TABLE IF NOT EXISTS cdr (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    caller_id numeric,
    recipient numeric,
    call_date text,
    end_time text,
    start_date_time text,
    end_date_time text,
    duration int,
    cost real,
    reference varchar(64),
    currency varchar(3),
    insert_datetime text,
    UNIQUE(caller_id,start_date_time)
);
create table version IF NOT EXISTS (version text);