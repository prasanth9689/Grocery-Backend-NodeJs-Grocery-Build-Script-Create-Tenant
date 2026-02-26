#!/bin/bash

# Pending Tenant uploads logic see readme file
# https://chatgpt.com/c/69883b8d-7c44-8321-b1a2-02005bd6c2a9

#######################################################
#       One time Tenant setup                         #
#  Use create_tenant.sh script for create new tenant  #                           
#######################################################

# Works
# Create Base App Folder grocery-backend
# And tenant database "tenants_master"
# And creating table "tenatns"
# Fetch code from github (industry based)
# This process only one time. when deployment on new server

RED='\033[0;31m'
YELLOW='\033[1;33m'
echo -e "${BOLD}${RED}CRITICAL: Very important!${NC}"
echo -e "${YELLOW} Configure wildcard certificates manually${NC}"

APP_DIR="/var/www/grocery-backend"
REPO_URL="https://github.com/yourusername/grocery-backend.git"
DOMAIN="skyblue.co.in"

DB_ROOT_USER="root"
DB_ROOT_PASS="prasanth"

PORT=5000

echo "=== Installing Dependencies ==="
apt update -y
# apt install -y nodejs npm mysql-server nginx certbot python3-certbot-nginx git
# npm install -g pm2

echo "=== Creating Project Directory ==="
mkdir -p $APP_DIR
cd $APP_DIR

npm init -y
npm install express mysql2 dotenv cors

mkdir -p src

echo "=== Creating .env ==="
cat <<EOF > .env
PORT=$PORT
DB_HOST=localhost
DB_ROOT_USER=$DB_ROOT_USER
DB_ROOT_PASS=$DB_ROOT_PASS
EOF

echo "=== Creating Master Tenant Database ==="
mysql -u$DB_ROOT_USER -p$DB_ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS tenants_master;
USE tenants_master;

CREATE TABLE IF NOT EXISTS tenants (
 id INT PRIMARY KEY AUTO_INCREMENT,
 name VARCHAR(100),
 subdomain VARCHAR(100) UNIQUE,
 db_name VARCHAR(100),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

echo "=== Creating Backend App ==="

cat <<EOF > src/app.js
const express = require('express');
const mysql = require('mysql2/promise');
require('dotenv').config();

const app = express();
app.use(express.json());

const masterPool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_ROOT_USER,
  password: process.env.DB_ROOT_PASS,
  database: "tenants_master",
  waitForConnections: true,
  connectionLimit: 10
});

const tenantPools = {};

async function getTenantPool(subdomain) {
  if (tenantPools[subdomain]) return tenantPools[subdomain];

  const [rows] = await masterPool.query(
    "SELECT db_name FROM tenants WHERE subdomain = ?",
    [subdomain]
  );

  if (rows.length === 0) return null;

  const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_ROOT_USER,
    password: process.env.DB_ROOT_PASS,
    database: rows[0].db_name,
    waitForConnections: true,
    connectionLimit: 10
  });

  tenantPools[subdomain] = pool;
  return pool;
}

app.use(async (req, res, next) => {
  const host = req.headers.host;
  const subdomain = host.split('.')[0];

  const tenantDB = await getTenantPool(subdomain);
  if (!tenantDB) {
    return res.status(404).json({ message: "Tenant not found" });
  }

  req.db = tenantDB;
  req.tenant = subdomain;
  next();
});

app.get('/api', async (req, res) => {
  const [rows] = await req.db.query("SELECT DATABASE() as db");
  res.json({
    tenant: req.tenant,
    database: rows[0].db
  });
});

app.listen(process.env.PORT, () => {
  console.log("SaaS running on port " + process.env.PORT);
});
EOF

echo "=== Starting Backend ==="
pm2 start src/app.js --name grocery-saas
pm2 save
pm2 startup systemd -u root --hp /root

echo "=== Configuring Nginx Wildcard ==="

# cat <<EOF > /etc/nginx/sites-available/skyblue
# server {
#     server_name *.skyblue.co.in;

#     location / {
#         proxy_pass http://localhost:$PORT;
#         proxy_set_header Host \$host;
#     }
# }
# EOF

# ln -sf /etc/nginx/sites-available/skyblue /etc/nginx/sites-enabled/
# nginx -t
# systemctl reload nginx

# echo "=== Installing Wildcard SSL ==="
# certbot --nginx -d "*.$DOMAIN" -d "$DOMAIN"

echo "=== SETUP COMPLETE ==="
