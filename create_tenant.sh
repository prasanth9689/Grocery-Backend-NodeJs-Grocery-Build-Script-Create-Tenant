#!/bin/bash
# Pending Tenant uploads logic see readme file
# https://chatgpt.com/c/69883b8d-7c44-8321-b1a2-02005bd6c2a9

SUBDOMAIN=$1
DB_NAME="grocery_${SUBDOMAIN}_db"

DB_ROOT_USER="root"
DB_ROOT_PASS="prasanth"

if [ -z "$SUBDOMAIN" ]; then
  echo "Usage: ./create_tenant.sh new client"
  exit 1
fi

echo "=== Creating Tenant Database ==="

mysql -u$DB_ROOT_USER -p$DB_ROOT_PASS <<EOF
CREATE DATABASE $DB_NAME;
USE $DB_NAME;

CREATE TABLE users (
 id INT PRIMARY KEY AUTO_INCREMENT,
 name VARCHAR(100),
 email VARCHAR(100),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
 id INT PRIMARY KEY AUTO_INCREMENT,
 name VARCHAR(150),
 price DECIMAL(10,2),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

mysql -u$DB_ROOT_USER -p$DB_ROOT_PASS <<EOF
USE tenants_master;
INSERT INTO tenants (name, subdomain, db_name)
VALUES ('$SUBDOMAIN','$SUBDOMAIN','$DB_NAME');
EOF

echo "Tenant created successfully."
echo "Access: https://$SUBDOMAIN.skyblue.co.in/api"
