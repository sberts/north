#!/bin/bash
yum install -y nginx
sed -i s/80/${server_port}/g /etc/nginx/nginx.conf

cat > /usr/share/nginx/html/index.html << EOF
<h1>${server_text}</h1>
<p>db address: ${db_address}</p>
<p>db port: ${db_port}</p>
EOF

systemctl start nginx