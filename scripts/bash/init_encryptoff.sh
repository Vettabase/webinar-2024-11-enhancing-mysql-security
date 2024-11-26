#!/bin/bash

echo "Encryptoff initialization..."

# Fix Permissions
chown -R mysql:mysql /var/lib/mysql/

# Wait for the database to be up
until mysql --defaults-file=/etc/.my.cnf -e "SELECT 1" &> /dev/null
do
  echo "Waiting for Encryptoff to be ready..."
  sleep 3
done

# Import Sakila DB
mysql --defaults-file=/etc/.my.cnf < /tmp/sql/sakila-schema.sql
mysql --defaults-file=/etc/.my.cnf < /tmp/sql/sakila-data.sql
