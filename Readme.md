## Containers with tools

### OpenSSL

* Dockerhub repo [dejanualex/curlopenssl](https://hub.docker.com/repository/docker/dejanualex/curlopenssl/general)
* OpenSSL 3.1.3 19 Sep 2023 (Library: OpenSSL 3.1.3 19 Sep 2023)

* Start container with interactive shell:
```bash
docker run --rm -it dejanualex/curlopenssl:1.0
# explicit 
docker run -rm -itu 0 dejanualex/curlopenssl:1.0  /bin/sh
```
* Start pod with interactive shell:
```bash
kubectl  run curlopenssl -i --tty --image=dejanualex/curlopenssl:1.0  -- sh
# if Session ended, resume using
kubectl  attach curlopenssl -c curlopenssl -i -t
```
---

### Mssql-tools

* Dockerhub repo [dejanualex/mssql-tools](https://hub.docker.com/repository/docker/dejanualex/mssql-tools/general)
* SQL Server Command Line Tool Version 13.1.0007: `sqlcmd` and `bcp` utilities

* Start container with interactive shell:
```bash
docker run --rm -it dejanualex/mssql-tools:1.0
# explicit 
docker run --rm -itu 0 dejanualex/mssql-tools:1.0 /bin/sh
```

* Start pod with interactive shell:
```bash
kubectl run mymsssql -i --tty --image=dejanualex/mssql-tools:1.0
# if Session ended, resume using
kubectl attach mymsssql -c mymsssql -i -t
```
---

### PGadmin

* Dockerhub repo [dejanualex/pgadmin4](https://hub.docker.com/repository/docker/dejanualex/pgadmin4/general)
* pgAdmin version 7: management tool for PostgreSQL

* Run the following to generate the credentials file:
```bash
# change them
cat<<EOF>>.env
PGADMIN_DEFAULT_EMAIL=alexandru.dejanu@email.com
PGADMIN_DEFAULT_PASSWORD=test123
EOF
```
* Start container in background:
```bash
docker run -p 5050:80 --env-file .env  dejanualex/pgadmin4:1.0 -d
```
