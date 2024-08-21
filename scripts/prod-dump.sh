#!/bin/bash

#------------------------------------------------------------------------------
# written by:   Lawrence McDaniel
# date:         2024-aug-16
#
# usage:        dump production state of the edxapp database to importable sql
#               files. This script is intended to be run on the production
#               server.
#------------------------------------------------------------------------------

# Database credentials
USER="root"
PWD="password"
DATABASE="edxapp"
BACKUPS_DIRECTORY="./exports"
S3_BUCKET="bridgeedu"

# Tables to export
TABLES=(
    "auth_user"
    "auth_userprofile"
    "courseware_studentmodule"
    "student_courseenrollment"
)

# Export each table with the new name
for TABLE in "${TABLES[@]}"; do
    NEW_TABLE="IMPORT_${TABLE}"
    OUTPUT_FILE="${BACKUPS_DIRECTORY}/${NEW_TABLE}.sql"
    
    # Remove the file if it exists
    if [ -f "$OUTPUT_FILE" ]; then
        rm "$OUTPUT_FILE"
    fi
    
    # Export the table and rename it in the SQL file
    mysqldump -u${USER} -p${PWD} ${DATABASE} ${TABLE} > "$OUTPUT_FILE"
    sed -i "s/\`${TABLE}\`/\`${NEW_TABLE}\`/g" "$OUTPUT_FILE"

    echo "Exported ${TABLE} to ${OUTPUT_FILE}."
    echo "Synching with S3"
    /usr/local/bin/aws s3 sync ${BACKUPS_DIRECTORY} s3://${S3_BUCKET}/sync
done

echo "Export completed."

