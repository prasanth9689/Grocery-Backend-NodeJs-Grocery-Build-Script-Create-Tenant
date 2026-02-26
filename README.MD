##  Uploads tenant 
Nginx reverse proxy, you must allow static files.
```
sudo nano /etc/nginx/sites-available/yourdomain
```

Make sure you have:
```
location /uploads/ {
    alias /var/www/grocery-backend;
}
```

Then:
```
sudo systemctl restart nginx
```

Folder permissions
It must have:

```
execute (x) permission on:
- /var
- /var/www
- /var/www/grocery-backend
- /var/www/grocery-backend/uploads
- /var/www/grocery-backend/uploads/tenant_1
```

Run this
```
sudo chmod o+rx /var/www/grocery-backend
```

Adding nginx to group<br>
Add nginx user to prasanth group:
```
sudo usermod -aG prasanth www-data
```

```
sudo chmod 755 /var/www/grocery-backend
sudo chmod -R 755 /var/www/grocery-backend/uploads
sudo systemctl reload nginx
```

app.js
```
const path = require("path");

app.use(
  "/uploads",
  express.static(path.join(__dirname, "../uploads"))
);
```

Url
```
https://test2.skyblue.co.in/uploads/tenant_1/apple.jpg
```

Restart PM2
```
pm2 restart all
```

Actual file structure
```
/var/www/grocery-backend/uploads
```