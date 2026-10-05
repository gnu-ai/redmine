#!/bin/bash
# Script: apply_deep_purple_theme.sh
# Description: Applique le theme violet profond/bleu nuit avec texte NOIR, champs BLANCS, menu BLANC, bandeau BLEU NUIT
# Usage: sudo ./apply_deep_purple_theme.sh

set -e

REDMINE_ROOT="/var/www/redmine-7.0.1"
CSS_SOURCE="$REDMINE_ROOT/app/assets/stylesheets/open-color-deep-purple-override.css"
CSS_PUBLIC="$REDMINE_ROOT/public/assets/stylesheets/open-color-deep-purple-override.css"

echo "=== Application du theme violet profond ==="
echo "- Fond: Violet profond / Bleu nuit"
echo "- Texte: NOIR"
echo "- Champs: BLANC"  
echo "- Menu: BLANC"
echo "- Bandeau (Home/Projet/Help): BLEU NUIT (#0F0F1A)"
echo "==="

cat > "$CSS_SOURCE" << "EOF"
/*
 * Override Open Color variables with Deep Purple / Midnight Blue theme
 * Custom deep purple theme with BLACK text, WHITE form fields, WHITE menu, BLUE NAVY header
 */

:root {
    --oc-indigo-0: #1A1A2E;
    --oc-indigo-1: #1F1F2E;
    --oc-indigo-2: #252538;
    --oc-indigo-3: #2F243D;
    --oc-indigo-4: #3D2B58;
    --oc-indigo-5: #4B3F72;
    --oc-indigo-6: #5D4F8C;
    --oc-indigo-7: #6D4C9C;
    --oc-indigo-8: #7A6DB5;
    --oc-indigo-9: #8B7DBC;
    --oc-grape-0: #252538;
    --oc-grape-1: #2F243D;
    --oc-grape-2: #3D2B58;
    --oc-grape-3: #4B3F72;
    --oc-grape-4: #5D4F8C;
    --oc-grape-5: #6D4C9C;
    --oc-grape-6: #7A6DB5;
    --oc-grape-7: #8B7DBC;
    --oc-grape-8: #9C8EC5;
    --oc-grape-9: #0F0F1A;
    --color-current-marker: var(--oc-indigo-5);
    --oc-gray-0: #1A1A2E;
    --oc-gray-1: #1F1F2E;
    --oc-gray-2: #252538;
    --oc-gray-3: #2F243D;
    --oc-gray-9: #222222;
    --oc-gray-8: #333333;
    --oc-gray-7: #444444;
    --oc-gray-6: #555555;
    --oc-red-5: #9C4C4C;
    --oc-red-7: #C92A2A;
    --oc-green-5: #4C9C4C;
    --oc-yellow-5: #9C864C;
    --oc-blue-5: #6D4C9C;
    --oc-blue-6: #8B7DBC;
    --oc-blue-7: #4B3F72;
}

body {
    background-color: var(--oc-indigo-0);
    color: var(--oc-gray-9);
}

.box, .panel, .card {
    background-color: var(--oc-indigo-1);
    border-color: var(--oc-indigo-4);
    color: var(--oc-gray-9);
}

#sidebar {
    background-color: var(--oc-gray-0);
    border-right-color: var(--oc-indigo-4);
    color: var(--oc-gray-9);
}

/* BANDEAU Home/Projet/Help - BLEU NUIT (#0F0F1A) */
#header {
    background-color: #0F0F1A !important;
    border-bottom-color: var(--oc-indigo-4);
    color: var(--oc-gray-9);
}

#top-menu {
    background-color: #0F0F1A !important;
    border-bottom: 1px solid var(--oc-indigo-4);
}

#main-menu {
    background-color: #0F0F1A !important;
    border-color: var(--oc-indigo-4);
}

.tabs {
    background-color: #0F0F1A !important;
    border-color: var(--oc-indigo-4);
}

.tabs a {
    color: #FFFFFF !important;
    background-color: transparent !important;
}

.tabs a.selected {
    background-color: var(--oc-indigo-4) !important;
    color: #FFFFFF !important;
    border-bottom-color: #0F0F1A !important;
}

.tabs a:hover {
    background-color: var(--oc-indigo-2) !important;
    color: #FFFFFF !important;
}

.general-menu {
    background-color: #0F0F1A !important;
}

.top-menu__links {
    background-color: #0F0F1A !important;
}

.profile-menu {
    background-color: #0F0F1A !important;
}

#account {
    background-color: #0F0F1A !important;
}

input[type="submit"],
input[type="button"],
button,
.a-button,
.btn {
    background-color: var(--oc-indigo-4);
    border-color: var(--oc-indigo-4);
    color: #FFFFFF;
}

input[type="submit"]:hover,
input[type="button"]:hover,
button:hover,
.a-button:hover,
.btn:hover {
    background-color: var(--oc-indigo-5);
}

a { color: var(--oc-blue-5); }
a:hover { color: var(--oc-blue-6); }

th {
    background-color: var(--oc-indigo-1);
    color: var(--oc-gray-9);
    border-bottom-color: var(--oc-indigo-4);
}

td { color: var(--oc-gray-9); }
tr:hover { background-color: var(--oc-indigo-2); }

input[type="text"],
input[type="email"],
input[type="number"],
input[type="password"],
input[type="search"],
textarea,
select {
    background-color: #FFFFFF;
    color: #222222;
    border-color: var(--oc-indigo-4);
}

.flash { border-radius: 6px; }
.flash.notice {
    background-color: rgba(109, 76, 156, 0.15);
    color: var(--oc-blue-6);
    border-left: 4px solid var(--oc-indigo-4);
}

::-webkit-scrollbar-thumb { background: var(--oc-indigo-4); }
::-webkit-scrollbar-track { background: var(--oc-indigo-1); }

p, div, span, h1, h2, h3, h4, h5, h6, li, ul, ol {
    color: var(--oc-gray-9);
}

#content, #sidebar, #header, #main, .wiki, .attributes, .subject, .description {
    color: #222222;
}

.flyout-menu {
    background-color: #0F0F1A !important;
    color: #FFFFFF !important;
}

/* Texte dans le bandeau - blanc pour contraste */
#top-menu, #top-menu a, #main-menu, #main-menu a {
    color: #FFFFFF !important;
}

#header h1, #header a {
    color: #FFFFFF !important;
}
EOF

cp "$CSS_SOURCE" "$CSS_PUBLIC"
chmod 644 "$CSS_SOURCE" "$CSS_PUBLIC"

echo "Precompilation des assets..."
cd "$REDMINE_ROOT"
RAILS_ENV=production bundle exec rails assets:precompile

echo "Redemarrage des services..."
systemctl restart redmine-puma nginx

echo ""
echo "=== Theme applique avec succes! ==="
echo "- Fond: Violet profond / Bleu nuit (#1A1A2E)"
echo "- Texte: NOIR (#222222)"
echo "- Champs de formulaire: BLANC (#FFFFFF)"
echo "- Menu: BLANC (#FFFFFF)"
echo "- Bandeau (Home/Projet/Help): BLEU NUIT (#0F0F1A)"
