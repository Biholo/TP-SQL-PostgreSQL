#!/bin/bash

# Script de démarrage pour l'environnement Docker
# Bibliothèque Universitaire - TP PostgreSQL

echo "🐳 Démarrage de l'environnement Docker - Bibliothèque Universitaire"
echo "=================================================================="

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé ou n'est pas accessible"
    echo "   Veuillez installer Docker : https://docs.docker.com/get-docker/"
    exit 1
fi

# Vérifier que Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    echo "   Veuillez installer Docker Compose : https://docs.docker.com/compose/install/"
    exit 1
fi

# Vérifier que Docker fonctionne
if ! docker ps &> /dev/null; then
    echo "❌ Docker ne fonctionne pas ou n'est pas démarré"
    echo "   Veuillez démarrer Docker et réessayer"
    exit 1
fi

echo "✅ Docker et Docker Compose sont disponibles"
echo ""

# Arrêter les conteneurs existants s'ils existent
echo "🔄 Nettoyage des conteneurs existants..."
docker-compose down -v 2>/dev/null

echo "🚀 Démarrage des conteneurs..."
echo ""

# Démarrer les conteneurs
if docker-compose up -d; then
    echo ""
    echo "⏳ Attente de l'initialisation de PostgreSQL..."
    
    # Attendre que PostgreSQL soit prêt
    sleep 5
    
    # Suivre les logs d'initialisation
    echo "📋 Logs d'initialisation :"
    echo "=========================="
    timeout 60 docker-compose logs -f postgres | grep -E "(🚀|📄|✅|🎉|NOTICE|ERROR)" || true
    
    echo ""
    echo "🎉 Environnement démarré avec succès !"
    echo ""
    echo "📊 Services disponibles :"
    echo "  PostgreSQL  : localhost:5432"
    echo "  PgAdmin     : http://localhost:8080"
    echo ""
    echo "🔗 Connexion à la base de données :"
    echo "  Utilisateur : admin"
    echo "  Mot de passe: admin123"
    echo "  Base        : bibliotheque_universitaire"
    echo ""
    echo "🧪 Pour tester la connexion :"
    echo "  docker exec -it bibliotheque_postgres psql -U admin -d bibliotheque_universitaire"
    echo ""
    echo "📚 Documentation complète : README-Docker.md"
    
else
    echo "❌ Erreur lors du démarrage des conteneurs"
    echo "📋 Logs d'erreur :"
    docker-compose logs
    exit 1
fi 