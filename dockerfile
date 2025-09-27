FROM alpine:3.20

ENV TZ="Europe/Berlin"

# Tools: Bash, Coreutils, Docker-CLI für Logs, Nginx als Webserver
RUN apk add --no-cache bash coreutils tzdata docker-cli nginx jq

WORKDIR /app
COPY report.sh /app/report.sh
RUN chmod +x /app/report.sh

# nginx vorbereiten (Alpine nutzt /etc/nginx/http.d/ statt conf.d)
RUN mkdir -p /run/nginx /var/log/nginx \
    && rm -rf /etc/nginx/http.d/*

# Minimal-Config für nginx: serve /data unter Port 8080
RUN cat > /etc/nginx/http.d/default.conf <<'EOF'
server {
    listen 8080;
    server_name localhost;

    # HTML-Reports (Default)
    root /data;
    index index.html;

    location / {
        autoindex on;
        try_files $uri $uri/ =404;
    }

    # API Endpoints → geben JSON zurück
    location /api/mounts {
        alias /data/mounts.json;
        default_type application/json;
    }

    location /api/logs {
        alias /data/logs.json;
        default_type application/json;
    }
}
EOF

# Entrypoint: Reportskript läuft im Hintergrund (aktualisiert Reports alle 5 Min),
# nginx läuft im Vordergrund
CMD ["/bin/bash", "-c", "/app/report.sh & nginx -g 'daemon off;'"]
