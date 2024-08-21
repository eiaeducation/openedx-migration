#!/bin/bash

#------------------------------------------------------------------------------
# written by:   Lawrence McDaniel
# date:         2024-aug-16
#
# usage:        import tables into the openedx database and insert rows into
#               the original tables, ignoring existing rows.
#------------------------------------------------------------------------------

# Database credentials
USER="root"
PWD="password"
DATABASE="openedx"
BACKUPS_DIRECTORY="./exports"
S3_BUCKET="bridgeedu"

if [ ! -d "$BACKUPS_DIRECTORY" ]; then
  mkdir -p "$BACKUPS_DIRECTORY"
fi

# Tables to import
TABLES=(
    "auth_user"
    "auth_userprofile"
    "courseware_studentmodule"
    "student_courseenrollment"
)

# Import each table and insert rows into the original table
for TABLE in "${TABLES[@]}"; do
    NEW_TABLE="IMPORT_${TABLE}"
    INPUT_FILE="${BACKUPS_DIRECTORY}/${NEW_TABLE}.sql"

    echo "Synching from S3"
    aws s3 sync s3://${S3_BUCKET}/sync ${BACKUPS_DIRECTORY} --delete

    # Import the table
    echo "Importing ${NEW_TABLE} from ${INPUT_FILE}"
    docker exec -i tutor_local-mysql-1 sh -c "exec mysql -u$USER -p$PWD -e 'USE openedx; DROP TABLE IF EXISTS ${NEW_TABLE};'"
    docker exec -i tutor_local-mysql-1 sh -c "exec mysql -u${USER} -p${PWD} ${DATABASE}" < "${INPUT_FILE}"
    
    # Insert rows into the original table, ignoring existing rows
    echo "Inserting into ${TABLE} from ${NEW_TABLE}"
    docker exec -i tutor_local-mysql-1 sh -c "exec mysql -u$USER -p$PWD -e 'USE openedx; INSERT IGNORE INTO ${TABLE} SELECT * FROM ${NEW_TABLE};'"
done

# docker exec -i tutor_local-mysql-1 sh -c "exec mysql -uroot -p5I27Wdkx -e 'USE openedx; INSERT IGNORE INTO auth_userprofile (id, name, meta, courseware, language, location, year_of_birth, gender, level_of_education, mailing_address, city, country, goals, bio, profile_image_uploaded_at, user_id, phone_number, state) SELECT id, name, meta, courseware, language, location, year_of_birth, gender, level_of_education, mailing_address, city, country, goals, bio, profile_image_uploaded_at, user_id, phone_number, state FROM IMPORT_auth_userprofile;'"

echo "Import and insert completed."