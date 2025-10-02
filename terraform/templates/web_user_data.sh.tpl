#!/bin/bash
set -euo pipefail
# Hardened user data: install minimal deps and run a custom Python server without directory listing.
amazon-linux-extras install epel -y || true
yum update -y
yum install -y python3

install -d -m 0755 /opt/web
echo "Revision: ${web_app_revision}" > /opt/web/revision.txt
cat > /opt/web/index.html <<'EOF'
<html>
 <head><title>sap2 demo</title></head>
 <body>
  <h1>Terraform Provisioned Web Server</h1>
  <p>DB endpoint: ${db_address}</p>
  <p>DB name: ${db_name}</p>
  <p>DB user: ${db_user}</p>
  <p>Directory listing disabled.</p>
 </body>
</html>
EOF

cat > /opt/web/server.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

INDEX_PATH = '/opt/web/index.html'

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            with open(INDEX_PATH, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(content)))
            self.end_headers()
            self.wfile.write(content)
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'Internal Server Error')

    def log_message(self, format, *args):
        # Quiet logging to avoid noisy syslog
        return

if __name__ == '__main__':
    port = 80
    HTTPServer(('', port), Handler).serve_forever()
EOF

cat > /etc/systemd/system/simple-web.service <<'EOF'
[Unit]
Description=Simple custom Python HTTP server (no directory listing)
After=network.target

[Service]
WorkingDirectory=/opt/web
ExecStart=/usr/bin/python3 /opt/web/server.py
Restart=always
User=root
ProtectSystem=full
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now simple-web.service
