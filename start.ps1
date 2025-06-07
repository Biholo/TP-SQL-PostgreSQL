# Script de demarrage pour l'environnement Docker
# Bibliotheque Universitaire - TP PostgreSQL

Write-Host "Demarrage de environnement Docker - Bibliotheque Universitaire" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Verifier que Docker est installe
try {
    $null = Get-Command docker -ErrorAction Stop
    Write-Host "Docker est disponible" -ForegroundColor Green
} catch {
    Write-Host "Docker nest pas installe ou nest pas accessible" -ForegroundColor Red
    Write-Host "   Veuillez installer Docker Desktop : https://docs.docker.com/get-docker/" -ForegroundColor Yellow
    exit 1
}

# Verifier que Docker Compose est installe
try {
    $null = Get-Command docker-compose -ErrorAction Stop
    Write-Host "Docker Compose est disponible" -ForegroundColor Green
} catch {
    Write-Host "Docker Compose nest pas installe" -ForegroundColor Red
    Write-Host "   Veuillez installer Docker Compose : https://docs.docker.com/compose/install/" -ForegroundColor Yellow
    exit 1
}

# Verifier que Docker fonctionne
try {
    docker ps | Out-Null
    Write-Host "Docker fonctionne correctement" -ForegroundColor Green
} catch {
    Write-Host "Docker ne fonctionne pas ou nest pas demarre" -ForegroundColor Red
    Write-Host "   Veuillez demarrer Docker Desktop et reessayer" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Arreter les conteneurs existants s'ils existent
Write-Host "Nettoyage des conteneurs existants..." -ForegroundColor Yellow
docker-compose down -v 2>$null

Write-Host "Demarrage des conteneurs..." -ForegroundColor Cyan
Write-Host ""

# Demarrer les conteneurs
try {
    docker-compose up -d
    
    Write-Host ""
    Write-Host "Attente de initialisation de PostgreSQL..." -ForegroundColor Yellow
    
    # Attendre que PostgreSQL soit pret
    Start-Sleep -Seconds 10
    
    # Verifier que PostgreSQL repond
    Write-Host "Verification de PostgreSQL..." -ForegroundColor Cyan
    $retries = 0
    do {
        $status = docker exec bibliotheque_postgres pg_isready -U admin 2>$null
        if ($status -match "accepting connections") {
            Write-Host "PostgreSQL est pret !" -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 2
        $retries++
        Write-Host "Attente..." -ForegroundColor Yellow
    } while ($retries -lt 15)
    
    # Test de la base de donnees
    Write-Host "Test de la base de donnees..." -ForegroundColor Cyan
    $testResult = docker exec bibliotheque_postgres psql -U admin -d bibliotheque_universitaire -c "\dt" 2>$null
    
    if ($testResult -match "auteur" -and $testResult -match "livre" -and $testResult -match "etudiant" -and $testResult -match "emprunt") {
        Write-Host "Base de donnees initialisee correctement (4 tables creees)" -ForegroundColor Green
    } else {
        Write-Host "Attention: Probleme avec initialisation" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Environnement demarre avec succes !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Services disponibles :" -ForegroundColor Cyan
    Write-Host "  PostgreSQL  : localhost:5432" -ForegroundColor White
    Write-Host "  PgAdmin     : http://localhost:8081" -ForegroundColor White
    Write-Host ""
    Write-Host "Connexion a la base de donnees :" -ForegroundColor Cyan
    Write-Host "  Utilisateur : admin" -ForegroundColor White
    Write-Host "  Mot de passe: admin123" -ForegroundColor White
    Write-Host "  Base        : bibliotheque_universitaire" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour tester la connexion :" -ForegroundColor Cyan
    Write-Host "  docker exec -it bibliotheque_postgres psql -U admin -d bibliotheque_universitaire" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation complete : README-Docker.md" -ForegroundColor Yellow
    
} catch {
    Write-Host "Erreur lors du demarrage des conteneurs" -ForegroundColor Red
    Write-Host "Logs d'erreur :" -ForegroundColor Yellow
    docker-compose logs
    exit 1
} 