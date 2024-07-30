# -----------------------------------------------------------------------------
# written by:   lawrence mcdaniel
#               https://lawrencemcdaniel.com
#
# date:         jul-2024
#
# usage:        migrate EIA data from legacy Open edX platform Koa to Nutmeg.
#
#               Assumes remote storage services are accessible in both
#               the source and target platforms.
#
#               Assumes that the mysql and mongo backup files were created using
#               these cookiecutter-generated bash scripts:
#                   - https://github.com/cookiecutter-openedx/cookiecutter-openedx-devops/blob/main/%7B%7Bcookiecutter.github_repo_name%7D%7D/scripts/openedx-backup-mysql.sh
#                   - https://github.com/cookiecutter-openedx/cookiecutter-openedx-devops/blob/main/%7B%7Bcookiecutter.github_repo_name%7D%7D/scripts/openedx-backup-mongodb.sh
#               Note that you can use these Jinja templates to create working
#               scripts regardless of whether your source platform uses the cookiecutter
#
#               Assumes that the target platform is
#               - deployed via tutor
#               - version Nutmeg or later.
#               - created via Cookiecutter. this is helpful but not required.
#               - kubernetes based
#
#               migrates the following:
#               - MySQL edxapp db to tutor's openedx db
#               - MongoDB edxapp db to tutor's openedx db
#               - AWS S3 storage bucket contents
# see also:
#   - https://discuss.openedx.org/t/how-to-move-through-tutor-versions-part-ii/9574/9
#   - https://discuss.openedx.org/t/upgrading-koa-to-nutmeg-why-dont-courses-appear/8287
#   - https://openedx.atlassian.net/wiki/spaces/COMM/pages/3249438723/How+to+migrate+from+a+native+deployment+to+a+tutor+deployment+of+the+Open+edX+platform
#
# Infrastructure notes
#
# running on a Cookiecutter Bastion EC2 instance.
# see: https://github.com/cookiecutter-openedx/cookiecutter-openedx-devops/tree/main/%7B%7Bcookiecutter.github_repo_name%7D%7D/terraform/stacks/modules/ec2_bastion
#
# size:     t3.xlarge (4 vCPU / 16Gib memory).
#           500Gib standard EBS drive volume
#           around 150Gib was in use at the end of the migration process
#           Note that smaller EC2 instance sizes failed for various reasons.
#
# it's a good idea to run 'df' at the onset of this procedure to take note of
# your available drive space.
# -----------------------------------------------------------------------------
source venv/bin/activate

# local environment variables
# -----------------------------------------------------------------------------
LOCAL_BACKUP_PATH="/home/ubuntu/migration/backups/"             # remote backup files from AWS S3 are sync'd to this location
LOCAL_TUTOR_DATA_DIRECTORY="$(tutor config printroot)/data/"

echo "LOCAL_BACKUP_PATH: ${LOCAL_BACKUP_PATH}"
echo "LOCAL_TUTOR_DATA_DIRECTORY: ${LOCAL_TUTOR_DATA_DIRECTORY}"


# source data
# -----------------------------------------------------------------------------
SOURCE_MYSQL_FILE_PREFIX="openedx-mysql-"                       # example file: openedx-mysql-20230324T000001.tgz
SOURCE_MYSQL_TAG="20240724T060001"                              # a timestamp identifier suffixed to all mysql backup files.
echo "SOURCE_MYSQL_FILE_: ${SOURCE_MYSQL_FILE_PREFIX}${SOURCE_MYSQL_TAG}"

SOURCE_MONGODB_PREFIX="openedx-mongo-"                             # example file: openedx-mongo-20230324T020001
SOURCE_MONGODB_TAG="20240724T060001"                            # a timestamp identifier suffixed to all mongodb backup files.
echo "SOURCE_MONGODB_FILE_: ${SOURCE_MONGODB_PREFIX}${SOURCE_MONGODB_TAG}"


SOURCE_AWS_S3_BACKUP_BUCKET="bridgeedu"                         # expecting to find folders ./backups/mysql and ./backups/mongodb inside this bucket
SOURCE_AWS_S3_STORAGE_BUCKET_SOURCE="bridgeedu"                 # assumes that your source platform uses AWS S3 for all storages
echo "SOURCE_AWS_S3_BACKUP_BUCKET: ${SOURCE_AWS_S3_BACKUP_BUCKET}"
echo "SOURCE_AWS_S3_STORAGE_BUCKET_SOURCE: ${SOURCE_AWS_S3_STORAGE_BUCKET_SOURCE}"

# target data
# -----------------------------------------------------------------------------
TARGET_AWS_S3_STORAGE_BUCKET="bridgeedu"
# TARGET_KUBERNETES_OPENEDX_NAMESPACE="SET-ME-PLEASE"             # the k8s namespace to which your target environment is deployed
# TARGET_KUBERNETES_SERVICE_NAMESPACE="SET-ME-PLEASE"             # the k8s namespace for your shared infrastructure services: mysql, mongo, redis, etcetera

# 1. Prepare the local environment
# -------------------------------
if [ ! -d "/home/ubuntu/migration" ]; then
    mkdir /home/ubuntu/migration
    echo "created directory /home/ubuntu/migration"
fi
if [ ! -d "/home/ubuntu/migration/backups" ]; then
    mkdir /home/ubuntu/migration/backups
    echo "created directory /home/ubuntu/migration/backups"
fi
if [ ! -d "/home/ubuntu/migration/backups/mysql" ]; then
    mkdir /home/ubuntu/migration/backups/mysql
    echo "created directory /home/ubuntu/migration/backups/mysql"
fi
if [ ! -d "/home/ubuntu/migration/backups/mongodb" ]; then
    mkdir /home/ubuntu/migration/backups/mongodb
    echo "created directory /home/ubuntu/migration/backups/mongodb"
fi
if [ ! -d "/home/ubuntu/migration/upgraded" ]; then
    mkdir /home/ubuntu/migration/upgraded
    echo "created directory /home/ubuntu/migration/upgraded"
fi

echo "Ubuntu 16.04 environment is ready."

# 2 sync the data migration backups folder contents to the local file system
# -------------------------------
aws s3 sync "s3://${SOURCE_AWS_S3_BACKUP_BUCKET}/backups" /home/ubuntu/migration/backups/mongodb/ --exclude "*" --include "openedx-mongo-20240724T060001.tgz"
aws s3 sync "s3://${SOURCE_AWS_S3_BACKUP_BUCKET}/backups" /home/ubuntu/migration/backups/mysql/ --exclude "*" --include "openedx-mysql-20240724T060001.tgz"
tar xvzf "${LOCAL_BACKUP_PATH}mysql/${SOURCE_MYSQL_FILE_PREFIX}${SOURCE_MYSQL_TAG}.tgz" --directory "${LOCAL_BACKUP_PATH}mysql/"
echo "AWS S3 storage bucket contents have been synced to the local file system."

# 3. sync the AWS S3 storage of the legacy platform to the target platform's bucket
# -------------------------------
# aws s3 sync s3://$SOURCE_AWS_S3_STORAGE_BUCKET_SOURCE s3://$TARGET_AWS_S3_STORAGE_BUCKET

# take care of any storage folder structure transformations for block storage, video, grades, etcetera
# aws s3 mv s3://$TARGET_AWS_S3_STORAGE_BUCKET/some-poorly-placed-folder/submissions_attachments/ s3://$TARGET_AWS_S3_STORAGE_BUCKET/submissions_attachments/ --recursive
# aws s3 mv s3://$TARGET_AWS_S3_STORAGE_BUCKET/some-poorly-placed-folder/grades-download/ s3://$TARGET_AWS_S3_STORAGE_BUCKET/grades-download/ --recursive

# -----------------------------------------------------------------------------
# 4. initialize Docker and tutor environments
#    see docker-init.sh
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 5. Setup your local tutor environment
#    see tutor-install-koa.sh
# -----------------------------------------------------------------------------


# 6. modify the db name inside your source mysql dump file
# -----------------------------------------------------------------------------
# If your source data comes from a native build (presumably Lilac or earlier)
# then the mysql database will be named 'edxapp', and needs to be renamed to
# 'openedx'
#
# Use sed to search-replace the source database name 'edxapp' for the Tutor
# database name 'openedx'.
# see: https://unix.stackexchange.com/questions/255373/replace-text-quickly-in-very-large-file
sed -i '/edxapp/ s//openedx/g' ${LOCAL_BACKUP_PATH}mysql/mysql-data-${SOURCE_MYSQL_TAG}.sql
echo "MySQL database name has been updated for import to tutor 'openedx'."

# 7. Import your legacy MySQL data
# -----------------------------------------------------------------------------
LOCAL_TUTOR_MYSQL_ROOT_USERNAME=$(tutor config printvalue MYSQL_ROOT_USERNAME)
LOCAL_TUTOR_MYSQL_ROOT_PASSWORD=$(tutor config printvalue MYSQL_ROOT_PASSWORD)
echo "LOCAL_TUTOR_MYSQL_ROOT_PASSWORD: ${LOCAL_TUTOR_MYSQL_ROOT_PASSWORD}"
echo "LOCAL_TUTOR_MYSQL_ROOT_USERNAME: ${LOCAL_TUTOR_MYSQL_ROOT_USERNAME}"

docker exec -i tutor_local_mysql_1 sh -c "exec mysql -u$LOCAL_TUTOR_MYSQL_ROOT_USERNAME -p$LOCAL_TUTOR_MYSQL_ROOT_PASSWORD -e 'DROP DATABASE IF EXISTS openedx;'"
docker exec -i tutor_local_mysql_1 sh -c "exec mysql -u$LOCAL_TUTOR_MYSQL_ROOT_USERNAME -p$LOCAL_TUTOR_MYSQL_ROOT_PASSWORD" < "${LOCAL_BACKUP_PATH}mysql/mysql-data-${SOURCE_MYSQL_TAG}.sql"

# 8. take care of any Tutor-specific conflicts that might exist in your MySQL data
# in my case there was a username name conflict with a service account user that tutor creates.
#
# You would encounter conflicts of this nature the first time you run 'tutor local launch' after having restored your MySQL database.
# -----------------------------------------------------------------------------

# 9. Import your legacy MongoDB
# -----------------------------------------------------------------------------
if [ -d "${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup" ]; then
    sudo rm -r "${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup"
    echo "pruned backup working folder "${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup""
fi

#
# move the source MongoDB backup data into a part of the Ubuntu file
# system where Tutor's mongo service Docker container can see it.
# NOTE: a 20Gib dump took anywhere from 5 to 10 minutes to copy
#
tar xvzf "${LOCAL_BACKUP_PATH}mongodb/${SOURCE_MONGODB_PREFIX}${SOURCE_MONGODB_TAG}.tgz" --directory "${LOCAL_BACKUP_PATH}mongodb/"

sudo mv "${LOCAL_BACKUP_PATH}mongodb/mongo-dump-${SOURCE_MONGODB_TAG}" ${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/
sudo mv ${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/mongo-dump-${SOURCE_MONGODB_TAG} ${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup
sudo chown -R systemd-coredump ${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup
sudo chgrp -R systemd-coredump ${LOCAL_TUTOR_DATA_DIRECTORY}mongodb/backup

# restore from your MongoDB backup.
# NOTE: "Error: Command failed with status 137: docker-compose" means that your EC2 instance is under-sized and ran out of memory
# during the restore operation.
tutor local exec mongodb bash
    # purge any existing data
    mongo                   # this does not require a username nor password
    use edxapp;
    db.dropDatabase();
    use openedx;
    db.dropDatabase();
    exit                    # you can disregard any console error messages from mongo

# 10. Upgrades
# NOTE the following in my case:
# - the upgrade --from=koa step only partially worked. The Django db migrations worked, but the MongoDB upgrade broke.
# - --from=lilac seems to have picked up where the other left off.
# - --from=maple was benign. it didn't perform any additional operations.
# -----------------------------------------------------------------------------

pip install "tutor[full]==12.2.0"       # installs Lilac by default
tutor local upgrade --from=koa          # upgrades MongoDb to v4.0.25
tutor local quickstart                  # accept all default responses.
                                        # you're now running Lilac

pip install "tutor[full]==13.3.1"       # installs Maple by default
tutor local upgrade --from=lilac        # this step doesn't appear to do anything
tutor local quickstart                  # accept all default responses. this step does a LOT.
                                        # you're now running Maple docker.io/overhangio/openedx:13.3.1
                                        #
                                        # your course version should have upgraded to version 16.
                                        # verify by running this query: SELECT id, version FROM openedx.course_overviews_courseoverview;

pip install "tutor[full]==14.2.4"       # installs Nutmeg by default
tutor local upgrade --from=maple        # pulls and runs docker.io/overhangio/openedx:14.2.4
                                        # generates this exception:
                                        # MySQLdb._exceptions.OperationalError: (1054, "Unknown column 'course_overviews_courseoverview.entrance_exam_enabled' in 'field list'")
                                        # because the db migration course_overviews.0026_courseoverview_entrance_exam runs out of sequence.
tutor local quickstart                  # accept all default responses.
                                        # you're now running Nutmeg
                                        #
                                        # your course version should have upgraded to version 17.


pip install "tutor[full]==15.3.9"       # installs Olive by default
tutor local upgrade --from=nutmeg       # pulls and runs docker.io/overhangio/openedx:15.3.9
tutor local quickstart                  # accept all default responses.
                                        # you're now running Olive

pip install "tutor[full]==16.1.8"       # installs Palm by default
tutor local upgrade --from=nutmeg       # pulls and runs docker.io/overhangio/openedx:16.1.8
tutor local quickstart                  # accept all default responses.
                                        # you're now running Palm

pip install "tutor[full]==17.0.6"       # installs Quince by default
tutor local upgrade --from=nutmeg       # pulls and runs docker.io/overhangio/openedx:17.0.6
tutor local quickstart                  # accept all default responses.
                                        # you're now running Quince

pip install "tutor[full]==18.1.2"       # installs Rosewood by default
tutor local upgrade --from=nutmeg       # pulls and runs docker.io/overhangio/openedx:18.1.2
tutor local quickstart                  # accept all default responses.
                                        # you're now running Rosewood

# IMPORTANT: we need to run legacy database transformation operations to
#            backfill any data that is assumed to exist in Nutmeg
#
#            these operations modify MySQL as well as MongoDB data.
#
#            these might take several minutes, depending on the size
#            of your MySQL data.
tutor local run cms ./manage.py cms backfill_course_tabs
tutor local run cms ./manage.py cms simulate_publish

