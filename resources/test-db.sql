create database tiny;
\c tiny;

create table public.user (
  id serial primary key,
  nombre varchar(20) not null,
  apellido varchar(20) not null
);

insert into public.user(id, nombre, apellido) values(nextval('user_id_seq'), 'jorge', 'ramirez');
insert into public.user(id, nombre, apellido) values(nextval('user_id_seq'), 'juan', 'perez');
