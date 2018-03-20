This GitLab package is based on the original Synology Package from [Synology Repo](https://www.synology.com/de-de/dsm/packages/Docker-GitLab).

**Download latest SPK**: [here](https://github.com/jboxberger/synology-gitlab-jboxberger/releases)  

## Packages:
- https://hub.docker.com/r/sameersbn/gitlab/
- https://hub.docker.com/_/redis/
- https://hub.docker.com/r/sameersbn/postgresql/

## Features: 
- All-In-One Installer
- Backup/Restore scripts
- restore custom ENVIRONMENT variables after update (any variable not in scripts/env_ignore)
- Use PostgreSQL instead of MariaDB (Gitlab dropped MariaDB support)
- SSL (SELF SIGNED) Out of the Box
- import Let's Encrypt / Syno SSL certificates (experimental see import-syno-cert)
 
## Supported Architectures
**x86 avoton bromolow cedarview braswell kvmx64 broadwell apollolake**  
Since i can't test all architectures i had to make a choice which i can cover or which i expect to work. If your architecture is not in this list, please feel free to contact me and we can give it a try.  

You can check the architecture of your device [here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model) 
or [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/General/What_kind_of_CPU_does_my_NAS_have).

# Backup
```
# backup files will be saved in docker/backup directory
# the backup contains the config files including !PASSWORDS! be shure to keep them in an safe place!

sudo ./var/packages/synology-gitlab-jboxberger/scripts/backup	
```
# Restore
```
# restoring to a mismatched GitLab Version (e.g. 10.1.4 backup file to 9.4.4 GitLab) my cause problems
# i highly reccommend to restore only matching backup and GitLab versions.
  
sudo ./var/packages/synology-gitlab-jboxberger/scripts/restore --restore-file "2018-02-23-00-31-24-gitlab-10.4.2.tar.gz"
```

# Migrate from stock 9.4.4-0050 Synology GitLab Package
```
1) Backup your GitLab data 
2) Unsinstall 9.4.4-0050 GitLab Package wihout deleting data
3) Install 9.4.4-0100 PostgreSQL GitLab Package
4) Execute migration script with the command below. You will get a schema version missmatch warning because
   of a bug in the stock package, just ignore and continue.
   sudo ./var/packages/synology-gitlab-jboxberger/scripts/migrate-m10 --maria-db-root-password "mdb10-root-password" --maria-db-database "mdb10-gitlab-databse-name"
5) You can now directrly update to GitLab 10.5.5
```

# Migrate from MariaDB 10 Version
```
1) Backup your GitLab data using the backup scripts 
2) Update to latest MDB10 GitLab Package, at least 10.1.4 or 10.2.5
3) Unsinstall MDB10 GitLab Package wihout deleting data
4) Install PostgreSQL GitLab Package with the same version from prevous installed MDB10 GitLab Package
5) Execute migration script with the command below  
 
sudo ./var/packages/synology-gitlab-jboxberger/scripts/migrate-m10 --maria-db-root-password "mdb10-root-password" --maria-db-database "mdb10-gitlab-databse-name"
```

# Updates
**Always backup data before update! _Please be patient during the Update process_**.   
The first docker container boot up - after installation/update - takes some minutes because GitLab needs to migrate the Database first, you can see the status in the GitLab container log (DSM docker backend). The Update is complete when the CPU begins to idle.    

#### DSM 6.1.4-15217 
| Prev. Version | New Version | Status             |
|---------------|-------------|--------------------|
| 10.1.4        | 10.2.5      | ok                 |
| 10.2.5        | 10.3.6      | ok                 |
| 10.3.6        | 10.4.1      | ok                 |
| 10.4.1        | 10.5.1      | ok                 |
| ------------- | ----------- | ------------------ |
|  9.4.4        | 10.5.5      | ok                 |
| 10.2.5        | 10.5.5      | ok                 |
| 10.5.1        | 10.5.5      | ok                 |
