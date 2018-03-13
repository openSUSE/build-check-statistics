-- 1 up
create table if not exists packages (
  id         integer primary key autoincrement,
  arch       text,
  code       text,
  errors     text,
  package    text,
  project    text,
  repository text,
  updated    text not null default current_timestamp,
  warnings   text
);
create table if not exists staging (
  id         integer primary key autoincrement,
  arch       text,
  code       text,
  errors     text,
  package    text,
  project    text,
  repository text,
  updated    text not null default current_timestamp,
  warnings   text
);

-- 1 down
drop table if exists packages;
drop table if exists staging;
