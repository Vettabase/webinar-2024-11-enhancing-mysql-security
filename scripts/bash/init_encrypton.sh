#!/bin/bash

echo "Encrypton initialization..."

# Create component_keyring_file if not exists
touch /var/lib/mysql-keyring/component_keyring_file

# Fix Permissions
chown -R mysql:mysql /var/lib/mysql/
chown -R mysql:mysql /var/lib/mysql-keyring/

# Wait for the database to be up
until mysql --defaults-file=/etc/.my.cnf -e "SELECT 1" &> /dev/null
do
  echo "Waiting for Encrypton to be ready..."
  sleep 3
done

# Reload Key
mysql --defaults-file=/etc/.my.cnf -e "ALTER INSTANCE RELOAD KEYRING"

# Import Sakila DB
mysql --defaults-file=/etc/.my.cnf < /tmp/sql/sakila-schema.sql
mysql --defaults-file=/etc/.my.cnf < /tmp/sql/sakila-data.sql
