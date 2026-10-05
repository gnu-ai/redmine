#!/bin/bash
# Script: restore_default_theme.sh
# Description: Restaure le theme par defaut de Redmine
# Usage: sudo ./restore_default_theme.sh

set -e

REDMINE_ROOT="/var/www/redmine-7.0.1"

echo "=== Restauration du theme par defaut ==="

# 1. Supprimer l'override CSS de base.html.erb
echo "Suppression de l'override CSS de base.html.erb..."
sed -i "s/ 'open-color-deep-purple-override',//" "$REDMINE_ROOT/app/views/layouts/base.html.erb"
sed -i "s/, 'open-color-deep-purple-override'//" "$REDMINE_ROOT/app/views/layouts/base.html.erb"
sed -i "s/'open-color-deep-purple-override'//" "$REDMINE_ROOT/app/views/layouts/base.html.erb"

# 2. Supprimer les fichiers CSS override
echo "Suppression des fichiers CSS override..."
rm -f "$REDMINE_ROOT/app/assets/stylesheets/open-color-deep-purple-override.css"
rm -f "$REDMINE_ROOT/public/assets/stylesheets/open-color-deep-purple-override.css"

# 3. Precompiler les assets
cd "$REDMINE_ROOT"
echo "Precompilation des assets..."
RAILS_ENV=production bundle exec rails assets:precompile

# 4. Redemarrer les services
echo "Redemarrage des services..."
systemctl restart redmine-puma nginx

echo ""
echo "=== Theme par defaut restaure avec succes! ==="
