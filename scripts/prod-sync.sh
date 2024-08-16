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
    INPUT_FILE="./exports/${NEW_TABLE}.sql"
    
    # Import the table
    mysql -u${USER} -p${PWD} ${DATABASE} < "$INPUT_FILE"
    
    # Insert rows into the original table, ignoring existing rows
    mysql -u${USER} -p${PWD} ${DATABASE} -e "
        INSERT IGNORE INTO ${TABLE} 
        SELECT * FROM ${NEW_TABLE};
    "
done

echo "Import and insert completed."