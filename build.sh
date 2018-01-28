#!/bin/bash

# @TODO
# maria db migration

IS_DEBUG=0

########################################################################################################################
# DEFAULT PARAMETERS
########################################################################################################################
gitlab_target_package_fqn="sameersbn/gitlab:10.2.5"
gitlab_target_package_download_size=700

postgresql_target_package_fqn="sameersbn/postgresql:9.6-2"
postgresql_target_package_download_size=83

redis_target_package_fqn="redis:3.2.11"
redis_target_package_download_size=41

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case $i in
        -rv=*|--redis-fqn=*)
            redis_target_package_fqn="${i#*=}"
        ;;
        -rs=*|--redis-download-size=*)
            redis_target_package_download_size="${i#*=}"
        ;;
        -pv=*|--postgresql-fqn=*)
            postgresql_target_package_fqn="${i#*=}"
        ;;
        -ps=*|--postgresql-download-size=*)
            postgresql_target_package_download_size="${i#*=}"
        ;;
        -gv=*|--gitlab-fqn=*)
            gitlab_target_package_fqn="${i#*=}"
        ;;
        -gs=*|--gitlab-download-size=*)
            gitlab_target_package_download_size="${i#*=}"
        ;;
        --debug)
            IS_DEBUG=1
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

########################################################################################################################
# PROCESS VARIABLES
########################################################################################################################
gitlab_target_package_name=$(echo "$gitlab_target_package_fqn" | cut -f1 -d:)
gitlab_target_package_version=$(echo "$gitlab_target_package_fqn" | cut -f2 -d:)
gitlab_target_package_name_escaped=$(echo "$gitlab_target_package_name" | tr '/' '-')

postgresql_target_package_name=$(echo "$postgresql_target_package_fqn" | cut -f1 -d:)
postgresql_target_package_version=$(echo "$postgresql_target_package_fqn" | cut -f2 -d:)
postgresql_target_package_name_escaped=$(echo "$postgresql_target_package_name" | tr '/' '-')

redis_target_package_name=$(echo "$redis_target_package_fqn" | cut -f1 -d:)
redis_target_package_version=$(echo "$redis_target_package_fqn" | cut -f2 -d:)
redis_target_package_name_escaped=$(echo "$redis_target_package_name" | tr '/' '-')

########################################################################################################################
# VARIABLES
########################################################################################################################
project_name="synology-gitlab-jboxberger"
current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
project_tmp="$current_dir/tmp"
project_src="$current_dir/src"
project_build="$current_dir/build/$gitlab_target_package_version"

########################################################################################################################
# INIT
########################################################################################################################
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
  [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y git jq python
fi

if [ -d $project_build ]; then
  rm -rf $project_build
fi
mkdir -p $project_build

if [ -d $project_tmp ]; then
  rm -rf $project_tmp
fi
mkdir -p "$project_tmp"

########################################################################################################################
# INITIALIZE BASE PACKAGE
########################################################################################################################
cp -R "$project_src/." "$project_tmp"

########################################################################################################################
# FIX LANG FILE
########################################################################################################################
cd "$project_tmp/scripts/lang"
ln -s enu default
cd "$current_dir"

synology_gitlab_config="$project_tmp/package/config/synology_gitlab"
synology_gitlab_db_config="$project_tmp/package/config/synology_gitlab_db"
redis_config="$project_tmp/package/config/synology_gitlab_redis"


########################################################################################################################
# MODIFY GITLAB VERSION
########################################################################################################################
jq -c --arg image "$gitlab_target_package_name:$gitlab_target_package_version"  '.image=$image' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config
jq -c '.is_package=false' <$synology_gitlab_config >$synology_gitlab_config".out" && mv $synology_gitlab_config".out" $synology_gitlab_config

jq -c --arg image "$postgresql_target_package_name:$postgresql_target_package_version"  '.image=$image' <$synology_gitlab_db_config >$synology_gitlab_db_config".out" && mv $synology_gitlab_db_config".out" $synology_gitlab_db_config
jq -c '.is_package=false' <$synology_gitlab_db_config >$synology_gitlab_db_config".out" && mv $synology_gitlab_db_config".out" $synology_gitlab_db_config

jq -c --arg image "$redis_target_package_name:$redis_target_package_version"  '.image=$image' <$redis_config >$redis_config".out" && mv $redis_config".out" $redis_config
jq -c '.is_package=false' <$redis_config >$redis_config".out" && mv $redis_config".out" $redis_config

########################################################################################################################
# UPDATE INFO FILE
########################################################################################################################
sed -i -e "/^version=/s/=.*/=\"$gitlab_target_package_version\"/" $project_tmp/INFO
sed -i -e "/^package=/s/=.*/=\"$project_name\"/" $project_tmp/INFO


########################################################################################################################
# UPDATE SCRIPT FILES
########################################################################################################################
sed -i -e "s|__PKG_NAME__|$project_name|g" $project_tmp/scripts/common
sed -i -e "s|__PKG_NAME__|$project_name|g" $project_tmp/package/ui/config

sed -i -e "s|__REDIS_PACKAGE_NAME__|$redis_target_package_name|g" $project_tmp/scripts/common
sed -i -e "s|__REDIS_PACKAGE_NAME_ESCAPED__|$redis_target_package_name_escaped|g" $project_tmp/scripts/common
sed -i -e "s|__REDIS_VERSION__|$redis_target_package_version|g" $project_tmp/scripts/common
sed -i -e "s|__REDIS_SIZE__|$redis_target_package_download_size|g" $project_tmp/scripts/common

sed -i -e "s|__POSTGRESQL_PACKAGE_NAME__|$postgresql_target_package_name|g" $project_tmp/scripts/common
sed -i -e "s|__POSTGRESQL_PACKAGE_NAME_ESCAPED__|$postgresql_target_package_name_escaped|g" $project_tmp/scripts/common
sed -i -e "s|__POSTGRESQL_VERSION__|$postgresql_target_package_version|g" $project_tmp/scripts/common
sed -i -e "s|__POSTGRESQL_SIZE__|$postgresql_target_package_download_size|g" $project_tmp/scripts/common
sed -i -e "s|__POSTGRESQL_SHARE__|gitlab-db|g" $project_tmp/scripts/common

sed -i -e "s|__GITLAB_PACKAGE_NAME__|$gitlab_target_package_name|g" $project_tmp/scripts/common
sed -i -e "s|__GITLAB_PACKAGE_NAME_ESCAPED__|$gitlab_target_package_name_escaped|g" $project_tmp/scripts/common
sed -i -e "s|__GITLAB_VERSION__|$gitlab_target_package_version|g" $project_tmp/scripts/common
sed -i -e "s|__GITLAB_SIZE__|$gitlab_target_package_download_size|g" $project_tmp/scripts/common

for wizzard_file in $project_tmp/WIZARD_UIFILES/* ; do
  sed -i -e "s|__PKG_NAME__|$project_name|g" $wizzard_file
done

########################################################################################################################
# ADD DOCKER IMAGES
########################################################################################################################
mkdir -p "$project_tmp/package/docker"

if [ -f "docker/$gitlab_target_package_name_escaped-$gitlab_target_package_version.tar.xz" ]; then
    cp -rf "docker/$gitlab_target_package_name_escaped-$gitlab_target_package_version.tar.xz" "$project_tmp/package/docker/$gitlab_target_package_name_escaped-$gitlab_target_package_version.tar.xz"
fi

if [ -f "docker/$postgresql_target_package_name_escaped-$postgresql_target_package_version.tar.xz" ]; then
    cp -rf "docker/$postgresql_target_package_name_escaped-$postgresql_target_package_version.tar.xz" "$project_tmp/package/docker/$postgresql_target_package_name_escaped-$postgresql_target_package_version.tar.xz"
fi

if [ -f "docker/$redis_target_package_name_escaped-$redis_target_package_version.tar.xz" ]; then
    cp -rf "docker/$redis_target_package_name_escaped-$redis_target_package_version.tar.xz" "$project_tmp/package/docker/$redis_target_package_name_escaped-$redis_target_package_version.tar.xz"
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################

# compress package dir
cd $project_tmp/package/ && tar -zcf ../package.tgz * && cd ../../

EXTRACTSIZE=$(du -k --block-size=1KB "$project_tmp/package.tgz" | cut -f1)
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" $project_tmp/INFO

# create spk-name
new_file_name=$project_name"-aio"$gitlab_target_package_version".spk"

cd $project_tmp/ && tar --format=gnu -cf $project_build/$new_file_name * --exclude='package' && cd ../
if [ $IS_DEBUG == 0 ]; then
  rm -rf "$project_tmp"
fi
