#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="/data"
mkdir -p "$OUT_DIR"

# ---- HTML Template ----
html_wrap() {
  local title="$1"
  local body="$2"
  cat <<EOF
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<meta http-equiv="refresh" content="300"> <!-- Browser-Refresh alle 5 Minuten -->
</head>
<body class="bg-light">
<div class="container my-5">
  <h1 class="mb-4">$title</h1>
  <p class="text-muted">Generated: $(date -u +"%Y-%m-%d %H:%M UTC")</p>
  $body
</div>
</body>
</html>
EOF
}

# ---- Mountpoints Report (HTML + JSON) ----
report_mounts() {
  local rows=""
  while read -r line; do
    dev=$(awk '{print $1}' <<< "$line")
    fstype=$(awk '{print $2}' <<< "$line")
    size=$(awk '{print $3}' <<< "$line")
    used=$(awk '{print $4}' <<< "$line")
    avail=$(awk '{print $5}' <<< "$line")
    usep=$(awk '{print $6}' <<< "$line")
    mnt=$(awk '{print $7}' <<< "$line")
    rows+="<tr><td>$dev</td><td>$mnt</td><td>$fstype</td><td>$size</td><td>$used</td><td>$avail</td><td>$usep</td></tr>"
  done < <(df -h --output=source,fstype,size,used,avail,pcent,target | tail -n +2)

  local body="<div class=\"table-responsive\">
    <table class=\"table table-striped table-bordered\">
      <thead class=\"table-dark\">
        <tr><th>Device</th><th>Mount</th><th>Type</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th></tr>
      </thead>
      <tbody>$rows</tbody>
    </table>
  </div>"

  html_wrap "Mountpoints Report" "$body" > "$OUT_DIR/mounts.html"

  # JSON-Ausgabe
  df -h --output=source,fstype,size,used,avail,pcent,target | tail -n +2 | \
    awk 'BEGIN { print "[" } 
         { printf "%s{\"device\":\"%s\",\"type\":\"%s\",\"size\":\"%s\",\"used\":\"%s\",\"avail\":\"%s\",\"usep\":\"%s\",\"mount\":\"%s\"}", 
                sep, $1, $2, $3, $4, $5, $6, $7; sep="," } 
         END { print "]" }' > "$OUT_DIR/mounts.json"
}

# ---- Logs Report (HTML + JSON) ----
report_logs() {
  local containers
  containers=$(docker ps --format '{{.Names}}' | grep -v 'report-server' || true)

  local tabs=""
  local content=""

  echo "[" > "$OUT_DIR/logs.json"
  local sep=""

  for c in $containers; do
    [ -z "$c" ] && continue
    logs=$(docker logs --tail 50 "$c" 2>&1 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    # HTML
    tabs+="<li class=\"nav-item\"><a class=\"nav-link\" data-bs-toggle=\"tab\" href=\"#$c\">$c</a></li>"
    content+="<div class=\"tab-pane fade\" id=\"$c\"><pre class=\"small bg-dark text-white p-2\" style=\"max-height:400px;overflow:auto;\">$logs</pre></div>"

    # JSON (roh, Logs als String)
    raw_logs=$(docker logs --tail 50 "$c" 2>&1 | jq -Rs .)
    echo "${sep}{\"container\":\"$c\",\"logs\":$raw_logs}" >> "$OUT_DIR/logs.json"
    sep=","
  done

  echo "]" >> "$OUT_DIR/logs.json"

  if [ -z "$tabs" ]; then
    content="<p class='text-muted'>Keine weiteren Container gefunden.</p>"
  else
    content="<ul class=\"nav nav-tabs\">$tabs</ul><div class=\"tab-content\">$content</div>"
  fi

  html_wrap "Container Logs Report" "$content" > "$OUT_DIR/logs.html"
}

# ---- Index Page ----
report_index() {
  local body="
  <div class=\"row g-4\">
    <div class=\"col-md-6\">
      <div class=\"card shadow-sm h-100\">
        <div class=\"card-body\">
          <h5 class=\"card-title\">Mountpoints</h5>
          <p class=\"card-text\">Übersicht über Dateisysteme und deren Auslastung.</p>
          <a href=\"mounts.html\" class=\"btn btn-primary\">HTML</a>
        </div>
      </div>
    </div>
    <div class=\"col-md-6\">
      <div class=\"card shadow-sm h-100\">
        <div class=\"card-body\">
          <h5 class=\"card-title\">Container Logs</h5>
          <p class=\"card-text\">Letzte Logzeilen aller laufenden Container.</p>
          <a href=\"logs.html\" class=\"btn btn-primary\">HTML</a>
        </div>
      </div>
    </div>
    <div class=\"col-md-6\">
      <div class=\"card shadow-sm h-100\">
        <div class=\"card-body\">
          <h5 class=\"card-title\">API Endpoints</h5>
          <p class=\"card-text\">Anzeige der API</p>
          <a href=\"mounts.json\" class=\"btn btn-primary\">Mounts</a>
          <a href=\"logs.json\" class=\"btn btn-secondary\">Container Logs</a>
        </div>
      </div>
    </div>
    <div class=\"col-md-6\">
      <div class=\"card shadow-sm h-100\">
        <div class=\"card-body\">
          <h5 class=\"card-title\">API Hilfe</h5>
          <p class=\"card-text\">Hilfe zur API</p>
          <a href=\"api-docs.html\" class=\"btn btn-secondary\">API Beispiel</a>
        </div>
      </div>
    </div>
  </div>"

  html_wrap "Reportserver Index" "$body" > "$OUT_DIR/index.html"
}

# ---- Main Loop ----
while true; do
  report_mounts
  report_logs
  report_index
  echo "Reports refreshed at $(date -u)"
  sleep 300   # 5 Minuten
done
