$ErrorActionPreference = "Stop"

# 1. Identifier la couleur actuellement active dans Nginx
$confNginx = docker compose exec -T nginx cat /etc/nginx/conf.d/default.conf 2>$null

if ($confNginx -match "server app-blue:5000;") {
    $currentColor = "blue"
    $targetColor = "green"
} else {
    $currentColor = "green"
    $targetColor = "blue"
}

$upstreamServer = "app-${targetColor}:5000"

Write-Host "=== Deploiement Blue/Green ===" -ForegroundColor Cyan
Write-Host "Couleur active : $currentColor"
Write-Host "Couleur cible  : $targetColor"

# 2. Demarrer le conteneur cible
Write-Host "--> Demarrage du conteneur app-$targetColor..."
docker compose --profile $targetColor up -d --build

# 3. Attendre le statut healthy
Write-Host "--> Attente du healthcheck pour app-$targetColor..."
$containerName = "starter-app-app-$targetColor-1"
$maxRetries = 20
$attempt = 0
$isHealthy =$false

while ($attempt -lt $maxRetries) {$status = docker inspect --format '{{json .State.Health.Status}}' $containerName 2>$null
    if ($status -eq '"healthy"') {
        $isHealthy =$true
        break
    }
    $attempt++
    Write-Host "Tentative $attempt/$maxRetries (statut:$status)..."
    Start-Sleep -Seconds 2
}

if (-not $isHealthy) {
    Write-Error "app-$targetColor n'est pas passee healthy. Annulation du deploiement."
    docker compose stop "app-$targetColor"
    exit 1
}

Write-Host "--> app-$targetColor est prete !" -ForegroundColor Green

# 4. Mettre a jour Nginx (localement et dans le conteneur)
Write-Host "--> Bascule de Nginx vers $targetColor..."
$confText = @"
upstream backend {
    server $upstreamServer;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
    }
}
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Resolve-Path .\nginx\default.conf).Path, $confText, $utf8NoBom)

docker compose exec -T nginx sh -c "cat << 'EOF' > /etc/nginx/conf.d/default.conf
upstream backend {
    server $upstreamServer;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
    }
}
EOF
nginx -t && nginx -s reload"

# 5. Arreter l'ancien conteneur
Write-Host "--> Arret de app-$currentColor..."
docker compose stop "app-$currentColor"

Write-Host "=== Deploiement vers $targetColor termine avec 0 interruption ! ===" -ForegroundColor Green