# Scripts de Correction des Sujets d'Issues Tronqués

Ces scripts permettent d'identifier et de corriger les issues Redmine dont les sujets (titres) ont été tronqués à cause des anciennes limites de longueur.

## 📋 Contexte

Avant la modification du code, Redmine tronquait les sujets d'issues à différentes longueurs :
- **60 caractères** : Dans les infobulles des liens (application_helper.rb)
- **100 caractères** : Dans certains titres (application_helper.rb)
- **30, 50 caractères** : Dans différentes vues

Ces limites ont été augmentées à **255 caractères** (la limite maximale de la base de données) pour correspondre à la validation du modèle Issue.

## 📁 Fichiers Disponibles

1. **`fix_truncated_issue_subjects.rb`** - Script de base
   - Identifie les issues avec sujets tronqués
   - Mode vérification ou correction
   - Génère des rapports CSV

2. **`fix_truncated_issue_subjects_enhanced.rb`** - Script avancé
   - ✅ **Fonctionnalité supplémentaire** : Essaie de récupérer les sujets originaux à partir des journaux (journals) de Redmine
   - Analyse plus détaillée
   - Peut générer des scripts SQL pour correction

## 🚀 Utilisation

### Script de Base

```bash
# Vérifier les issues tronquées (mode par défaut)
cd /var/www/redmine-7.0.1
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects.rb --check

# Vérifier avec limite
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects.rb --check --limit 10

# Vérifier avec longueur personnalisée
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects.rb --check --length 100

# Affiche l'aide
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects.rb --help
```

### Script Avancé (Recommandé)

```bash
# Vérifier avec récupération depuis les journaux
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects_enhanced.rb --recover --limit 10

# Générer un script SQL pour correction
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects_enhanced.rb --recover --limit 5

# Simulation (dry run) avec récupération
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects_enhanced.rb --recover --dry-run
```

## 📊 Résultats

Le script a identifié **94 issues** avec des sujets potentiellement tronqués :
- 17 issues avec exactement 60 caractères
- 18 issues avec 59 caractères
- 11 issues avec 56 caractères
- etc.

## 🔧 Correction Manuelle

### Méthode 1 : Via l'Interface Web
1. Exécutez le script avec `--recover` pour voir les sujets tronqués
2. Notez les IDs des issues à corriger
3. Allez dans Redmine → Issues
4. Éditez chaque issue et corrigez le sujet manuellement

### Méthode 2 : Via SQL (pour les administrateurs)

```bash
# 1. Générez le script SQL
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects_enhanced.rb --recover

# 2. Si vous choisissez de générer le script SQL, exécutez :
PGPASSWORD='JusteVivreHeureuse2029' psql -h 127.0.0.1 -U redmine -d redmine -f fix_issue_subjects_YYYYMMDD_HHMMSS.sql
```

⚠️ **IMPORTANT** : Faites toujours une sauvegarde avant d'exécuter des scripts SQL de modification !

```bash
# Sauvegarde de la base de données
pg_dump -h 127.0.0.1 -U redmine -d redmine > redmine_backup_$(date +%Y%m%d).sql
```

## 🎯 Récupération Automatique

Le script avancé essaiera de récupérer les sujets originaux à partir des **journaux** (journals) de Redmine. 

**Comment ça marche ?**
1. Quand un sujet est modifié, l'ancienne valeur est stockée dans les détails du journal
2. Le script cherche dans l'historique des modifications
3. Si un sujet plus long est trouvé, il est considéré comme l'original

**Limitations :**
- Les sujets jamais modifiés après leur création ne peuvent pas être récupérés
- Si les journaux ont été purgés, les données sont perdues
- Seuls les sujets modifiés APRES le tronquage peuvent être récupérés

## 📈 Statistiques

Exécutez le script pour obtenir des statistiques à jour :

```bash
sudo -u redmine bundle exec ruby script/fix_truncated_issue_subjects_enhanced.rb --recover
```

Cela affichera :
- Nombre total d'issues avec sujets tronqués
- Répartition par longueur
- Nombre de sujets récupérables depuis les journaux

## 🛡️ Bonnes Pratiques

1. **Toujours faire une sauvegarde** avant toute modification en masse
2. **Tester sur un environnement de développement** d'abord
3. **Vérifier les résultats** après correction
4. **Communiquer avec l'équipe** avant de modifier des issues existantes

## 📞 Support

Pour plus d'aide ou pour signaler des problèmes avec ces scripts :
- Vérifiez que les dépendances sont installées (`pg` gem)
- Assurez-vous que les identifiants de la base de données sont corrects
- Consultez les logs pour les erreurs de connexion

## 🔄 Mises à Jour Futures

Ces scripts peuvent être améliorés avec :
- Correction automatique directe (si l'accès en écriture est autorisé)
- Export/Import complet avec validation
- Intégration avec l'API Redmine
- Interface web pour la correction
