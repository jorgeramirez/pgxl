# PGXL

This is the Dockerfile for [pgxl](https://hub.docker.com/r/jorgeramirez/pgxl/) image  that runs a [Postgres-XL](http://www.postgres-xl.org/) cluster The Postgres-XL cluster is made of one coordinator and two datanodes. Good for testing purposes.


## Build & Run

```
$ docker build --tag=pgxl .
$ docker run -d -P --name pgxl pgxl
```

Now you have a running cluster, to interact with you can log into the running container 
and use psql.

```
$ docker exec -it pgxl /bin/bash
$ psql
```

### Custom DB initialization

```
# Dockerfile
FROM jorgeramirez/pgxl

ADD init.sql /pgxl-initdb.d/
```


### Credentials

Database user/password

```
postgres/postgres
```

SO root user/password

```
root/admin
```
