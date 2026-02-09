#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN="grocery.skyblue.co.in"
API_PATH="/api"
APP_DIR="/var/www/grocery.skyblue.co.in"
APP_PORT=3000

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

2000
10
60
280

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install Node.js
echo -e "${YELLOW}Installing Node.js ${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt install -y nodejs

# Create application directory
echo -e "${YELLOW}Creating application directory...${NC}"
mkdir -p $APP_DIR
cd $APP_DIR

# Initialize package.json
echo -e "${YELLOW}Initializing Node.js project...${NC}"
cat > package.json <<EOF
{
  "name": "grocery-api",
  "version": "1.0.0",
  "description": "Grocery API Backend",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "pm2:start": "pm2 start ecosystem.config.js",
    "pm2:stop": "pm2 stop grocery-api",
    "pm2:restart": "pm2 restart grocery-api",
    "pm2:logs": "pm2 logs grocery-api"
  },
  "keywords": ["api", "grocery", "backend"],
  "author": "",
  "license": "ISC"
}
EOF

# Install important Node.js packages
echo -e "${YELLOW}Installing Node.js dependencies...${NC}"
npm install express \
    dotenv \
    cors \
    helmet \
    morgan \
    express-rate-limit \
    mongoose \
    mysql2 \
    pg \
    sequelize \
    bcryptjs \
    jsonwebtoken \
    validator \
    express-validator \
    multer \
    axios \
    compression \
    cookie-parser \
    body-parser \
    nodemailer \
    moment \
    uuid

# Install dev dependencies
npm install --save-dev nodemon

# Create .env file
echo -e "${YELLOW}Creating .env file...${NC}"
cat > .env <<EOF
# Server Configuration
NODE_ENV=production
PORT=$APP_PORT
HOST=localhost

# Database Configuration (MongoDB)
MONGODB_URI=mongodb://localhost:27017/grocery_db

# Database Configuration (MySQL) - Uncomment if using MySQL
DB_HOST=localhost
DB_PORT=3306
DB_NAME=grocery
DB_USER=root
DB_PASSWORD=prasanth

# Database Configuration (PostgreSQL) - Uncomment if using PostgreSQL
# PG_HOST=localhost
# PG_PORT=5432
# PG_DATABASE=grocery_db
# PG_USER=postgres
# PG_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRE=7d
JWT_COOKIE_EXPIRE=7

# Email Configuration (Optional)
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=your_email@gmail.com
# SMTP_PASSWORD=your_password
# FROM_EMAIL=noreply@grocery.skyblue.co.in
# FROM_NAME=Grocery API

# API Configuration
API_URL=https://$DOMAIN$API_PATH
FRONTEND_URL=https://grocery.skyblue.co.in

# Rate Limiting
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100

# File Upload
MAX_FILE_SIZE=5242880
FILE_UPLOAD_PATH=./public/uploads

# CORS
ALLOWED_ORIGINS=https://grocery.skyblue.co.in,http://localhost:3000

# Other
LOG_LEVEL=info
EOF

# Create server.js
echo -e "${YELLOW}Creating server.js...${NC}"
cat > server.js <<'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');

const app = express();

// Security Middleware
app.use(helmet());

// CORS Configuration
const corsOptions = {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true,
    optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Body Parser Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(cookieParser());

// Compression Middleware
app.use(compression());

// Logging Middleware
if (process.env.NODE_ENV === 'development') {
    app.use(morgan('dev'));
} else {
    app.use(morgan('combined'));
}

// Rate Limiting
const limiter = rateLimit({
    windowMs: (parseInt(process.env.RATE_LIMIT_WINDOW) || 15) * 60 * 1000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api', limiter);

// Static Files
app.use('/uploads', express.static('public/uploads'));

// Health Check Route
app.get('/health', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV
    });
});

// API Routes
app.get('/api', (req, res) => {
    res.status(200).json({
        success: true,
        message: 'Grocery API is running',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            api: '/api'
        }
    });
});

// Import your routes here
// const productRoutes = require('./routes/products');
// const userRoutes = require('./routes/users');
// const orderRoutes = require('./routes/orders');
// app.use('/api/products', productRoutes);
// app.use('/api/users', userRoutes);
// app.use('/api/orders', orderRoutes);

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

// Global Error Handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    const statusCode = err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
    
    res.status(statusCode).json({
        success: false,
        error: message,
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// Server Configuration
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || 'localhost';

const server = app.listen(PORT, HOST, () => {
    console.log(`
╔════════════════════════════════════════╗
║   Server running on ${HOST}:${PORT}   ║
║   Environment: ${process.env.NODE_ENV}              ║
║   Press Ctrl+C to stop                 ║
╚════════════════════════════════════════╝
    `);
});

// Graceful Shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});

module.exports = app;
EOF

# Create PM2 ecosystem config
echo -e "${YELLOW}Creating PM2 ecosystem config...${NC}"
cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'grocery-api',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: $APP_PORT
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Create logs directory
mkdir -p logs
mkdir -p public/uploads

# Create directory structure for routes, controllers, models
mkdir -p routes controllers models middleware config utils

# Create a sample route file
cat > routes/sample.js <<'EOF'
const express = require('express');
const router = express.Router();

// Sample GET route
router.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Sample route working'
    });
});

module.exports = router;
EOF


# Set proper permissions
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR

# Start application with PM2
echo -e "${YELLOW}Starting application with PM2...${NC}"
cd $APP_DIR
pm2 start ecosystem.config.js

# Save PM2 process list
pm2 save

# Setup PM2 to start on boot
pm2 startup systemd -u root --hp /root

# Create README
cat > README.md <<EOF
# Grocery API Backend

## Quick Start Commands

### PM2 Commands
\`\`\`bash
pm2 start ecosystem.config.js    # Start application
pm2 stop grocery-api              # Stop application
pm2 restart grocery-api           # Restart application
pm2 logs grocery-api              # View logs
pm2 monit                         # Monitor application
pm2 status                        # Check status
\`\`\`

### Nginx Commands
\`\`\`bash
sudo systemctl status nginx       # Check nginx status
sudo systemctl restart nginx      # Restart nginx
sudo nginx -t                     # Test nginx config
sudo systemctl reload nginx       # Reload nginx
\`\`\`

### Application Commands
\`\`\`bash
npm start                         # Start normally
npm run dev                       # Start with nodemon (development)
\`\`\`

## Important Files
- \`.env\` - Environment variables
- \`server.js\` - Main server file
- \`ecosystem.config.js\` - PM2 configuration
- \`/etc/nginx/sites-available/grocery-api\` - Nginx configuration

## SSL Setup (Optional)
\`\`\`bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN
\`\`\`

## API Endpoints
- Health Check: https://$DOMAIN/health
- API Base: https://$DOMAIN$API_PATH

## Directory Structure
\`\`\`
$APP_DIR/
├── server.js
├── package.json
├── .env
├── ecosystem.config.js
├── routes/
├── controllers/
├── models/
├── middleware/
├── config/
├── utils/
├── public/
│   └── uploads/
└── logs/
\`\`\`
EOF

# Display completion message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Application Directory:${NC} $APP_DIR"
echo -e "${YELLOW}API URL:${NC} http://$DOMAIN$API_PATH"
echo -e "${YELLOW}Health Check:${NC} http://$DOMAIN/health"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Edit .env file: ${GREEN}nano $APP_DIR/.env${NC}"
echo -e "2. Add your routes in: ${GREEN}$APP_DIR/routes/${NC}"
echo -e "3. View logs: ${GREEN}pm2 logs grocery-api${NC}"
echo -e "4. Check status: ${GREEN}pm2 status${NC}"
echo ""
echo -e "${YELLOW}Optional - Setup SSL:${NC}"
echo -e "   ${GREEN}sudo apt install certbot python3-certbot-nginx${NC}"
echo -e "   ${GREEN}sudo certbot --nginx -d $DOMAIN${NC}"
echo ""
echo -e "${GREEN}Server is running and accessible at:${NC}"
echo -e "   http://$DOMAIN$API_PATH"
echo -e "${GREEN}========================================${NC}"

# Show PM2 status
pm2 status

exit 0
EOF