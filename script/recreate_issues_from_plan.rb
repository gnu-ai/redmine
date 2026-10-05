#!/usr/bin/env ruby
# frozen_string_literal: true

# Script pour supprimer et recréer toutes les issues à partir de plan.md
# ATTENTION: Ce script SUPPRIME toutes les issues existantes!
#
# Utilisation: ruby script/recreate_issues_from_plan.rb [options]
#
# Options:
#   --dry-run           Simulation (ne supprime pas, ne crée pas)
#   --backup            Faire une sauvegarde avant suppression (recommandé)
#   --project ID        ID du projet (default: 1 - Neuron Translator)
#   --tracker ID       ID du tracker (default: 2 - Fonctionnalité)
#   --author ID        ID de l'auteur (default: 1 - admin)
#   --status ID        ID du statut (default: 1 - Nouveau)
#   --priority ID      ID de la priorité (default: 2 - Normale)
#   --help, -h         Affiche cette aide

require 'optparse'
require 'pg'
require 'fileutils'

class IssueRecreator
  DEFAULT_CONFIG = {
    host: '127.0.0.1',
    database: 'redmine',
    username: 'redmine',
    password: 'JusteVivreHeureuse2029',
    port: 5432
  }.freeze

  DEFAULT_OPTIONS = {
    project_id: 1,
    tracker_id: 2,
    author_id: 1,
    status_id: 1,
    priority_id: 2
  }.freeze

  def initialize(args = [])
    @options = parse_options(args)
    @db_config = DEFAULT_CONFIG
    @connection = nil
  end

  def parse_options(args)
    options = DEFAULT_OPTIONS.merge({
      dry_run: false,
      backup: true,
      show_help: false
    })

    parser = OptionParser.new do |opts|
      opts.banner = "Utilisation: ruby #{__FILE__} [options]"

      opts.separator ""
      opts.separator "Options :"

      opts.on("--dry-run", "Simulation (ne supprime pas, ne crée pas)") do |v|
        options[:dry_run] = v
      end

      opts.on("--[no-]backup", "Faire une sauvegarde avant suppression (default: oui)") do |v|
        options[:backup] = v
      end

      opts.on("--project ID", Integer, "ID du projet (default: #{DEFAULT_OPTIONS[:project_id]})") do |v|
        options[:project_id] = v
      end

      opts.on("--tracker ID", Integer, "ID du tracker (default: #{DEFAULT_OPTIONS[:tracker_id]})") do |v|
        options[:tracker_id] = v
      end

      opts.on("--author ID", Integer, "ID de l'auteur (default: #{DEFAULT_OPTIONS[:author_id]})") do |v|
        options[:author_id] = v
      end

      opts.on("--status ID", Integer, "ID du statut (default: #{DEFAULT_OPTIONS[:status_id]})") do |v|
        options[:status_id] = v
      end

      opts.on("--priority ID", Integer, "ID de la priorité (default: #{DEFAULT_OPTIONS[:priority_id]})") do |v|
        options[:priority_id] = v
      end

      opts.on("--help", "-h", "Affiche cette aide") do |v|
        options[:show_help] = v
      end
    end

    parser.parse!(args)
    options
  end

  def show_help
    puts <<~HELP
      Script pour supprimer et recréer toutes les issues à partir de plan.md

      ATTENTION: Ce script SUPPRIME toutes les issues existantes!

      Utilisation: ruby #{__FILE__} [options]

      Options:
        --dry-run           Simulation (ne supprime pas, ne crée pas)
        --[no-]backup       Faire une sauvegarde avant suppression (default: oui)
        --project ID        ID du projet (default: 1 - Neuron Translator)
        --tracker ID       ID du tracker (default: 2 - Fonctionnalité)
        --author ID        ID de l'auteur (default: 1)
        --status ID        ID du statut (default: 1 - Nouveau)
        --priority ID      ID de la priorité (default: 2 - Normale)
        --help, -h         Affiche cette aide

      Exemples:
        ruby #{__FILE__} --dry-run
        ruby #{__FILE__} --backup --project 1 --tracker 2
        ruby #{__FILE__} --no-backup --dry-run

      Projets disponibles:
        1: Neuron Translator
        2: Data Base Translator
        3: Inference Translator
        4: Orchestrator Translator
        5: Mistral VM Debian Hurd
        6: Httpfs Translator
        7: Hurd

      Trackers disponibles:
        1: Bug
        2: Fonctionnalité
        3: Support
    HELP
  end

  def connect_db
    @connection = PG.connect(
      host: @db_config[:host],
      dbname: @db_config[:database],
      user: @db_config[:username],
      password: @db_config[:password],
      port: @db_config[:port]
    )
  rescue PG::Error => e
    puts "❌ Erreur de connexion: #{e.message}"
    exit(1)
  end

  def disconnect_db
    @connection&.close
  end

  def execute_query(query, params = [])
    if params.empty?
      @connection.exec(query)
    else
      @connection.exec_params(query, params)
    end
  end

  def backup_issues
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    backup_file = "backup_issues_#{timestamp}.sql"
    
    puts "🔄 Création de la sauvegarde: #{backup_file}"
    
    # Exporter toutes les issues
    result = execute_query("SELECT * FROM issues ORDER BY id")
    
    File.open(backup_file, 'w') do |file|
      file.puts "-- Sauvegarde des issues - #{timestamp}"
      file.puts "-- Généré par recreate_issues_from_plan.rb"
      file.puts
      
      result.each do |row|
        # Générer INSERT pour chaque issue
        columns = row.keys.join(', ')
        values = row.values.map { |v| v.nil? ? 'NULL' : @connection.quote(v) }.join(', ')
        file.puts "INSERT INTO issues (#{columns}) VALUES (#{values});"
      end
    end
    
    puts "✅ Sauvegarde créée: #{backup_file} (#{result.count} issues)"
    backup_file
  end

  def delete_all_issues
    puts "🗑️  Suppression de toutes les issues existantes..."
    
    # Compter avant suppression
    count_result = execute_query("SELECT COUNT(*) as cnt FROM issues")
    count = count_result.first['cnt'].to_i
    
    if count == 0
      puts "⚠️  Aucune issue à supprimer"
      return 0
    end
    
    puts "   Trouvées: #{count} issues à supprimer"
    
    unless @options[:dry_run]
      # Supprimer toutes les issues
      execute_query("DELETE FROM issues")
      puts "✅ Toutes les issues supprimées"
    else
      puts "📝 Simulation: #{count} issues seraient supprimées"
    end
    
    count
  end

  def extract_issues_from_plan
    issues = []
    
    unless File.exist?('/var/www/redmine-7.0.1/plan.md')
      puts "❌ Fichier plan.md introuvable!"
      exit(1)
    end
    
    File.readlines('/var/www/redmine-7.0.1/plan.md').each do |line|
      # Match lines with issue format: - [ ] #ID: description
      if line.strip =~ /^- \[ \] #(\d+): (.+)$/
        id = $1.to_i
        description = $2.strip
        issues << {id: id, subject: description}
      end
    end
    
    puts "✅ Extrait #{issues.length} issues du plan.md"
    puts "   Plage d'IDs: #{issues.map { |i| i[:id] }.min} à #{issues.map { |i| i[:id] }.max}"
    
    # Vérifier les doublons
    ids = issues.map { |i| i[:id] }
    duplicates = ids.select { |id| ids.count(id) > 1 }.uniq
    if duplicates.any?
      puts "⚠️  Attention: IDs en double: #{duplicates.join(', ')}"
    end
    
    issues
  end

  def create_issues(issues)
    puts "📝 Création de #{issues.length} nouvelles issues..."
    
    unless @options[:dry_run]
      created_count = 0
      errors = []
      
      issues.each do |issue|
        begin
          # Insérer l'issue
          result = execute_query(
            "INSERT INTO issues (id, subject, project_id, tracker_id, author_id, status_id, priority_id, created_on, updated_on) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW()) RETURNING id",
            [issue[:id], issue[:subject], @options[:project_id], @options[:tracker_id], @options[:author_id], @options[:status_id], @options[:priority_id]]
          )
          
          if result.first && result.first['id']
            created_count += 1
            print "." if created_count % 10 == 0
          end
        rescue PG::Error => e
          errors << "ID #{issue[:id]}: #{e.message}"
        end
      end
      
      puts "\n✅ #{created_count} issues créées"
      
      unless errors.empty?
        puts "⚠️  Erreurs: #{errors.length}"
        errors.first(5).each { |e| puts "   - #{e}" }
      end
    else
      puts "📝 Simulation: #{issues.length} issues seraient créées"
      issues.first(5).each do |issue|
        puts "   - ##{issue[:id]}: #{issue[:subject][0..60]}#{'...' if issue[:subject].length > 60}"
      end
    end
    
    issues.length
  end

  def run
    if @options[:show_help]
      show_help
      return
    end

    puts "\n" + "=" * 80
    puts "SCRIPT DE RECRÉATION DES ISSUES À PARTIR DE PLAN.MD"
    puts "=" * 80
    puts "⚠️  ATTENTION: Ce script va SUPPRIMER toutes les issues existantes!"
    puts "=" * 80
    puts

    # Vérifier que le fichier plan.md existe
    unless File.exist?('/var/www/redmine-7.0.1/plan.md')
      puts "❌ Fichier /var/www/redmine-7.0.1/plan.md introuvable!"
      exit(1)
    end

    connect_db

    # Étape 1: Extraire les issues du plan.md
    issues = extract_issues_from_plan

    # Étape 2: Sauvegarde (si demandé)
    if @options[:backup] && !@options[:dry_run]
      backup_file = backup_issues
    elsif @options[:backup] && @options[:dry_run]
      puts "📝 Simulation: Une sauvegarde serait créée"
    end

    # Étape 3: Supprimer les issues existantes
    deleted_count = delete_all_issues

    # Étape 4: Créer les nouvelles issues
    created_count = create_issues(issues)

    # Résumé
    puts "\n" + "=" * 80
    puts "RÉSUMÉ"
    puts "=" * 80
    puts "Mode: #{@options[:dry_run] ? 'SIMULATION' : 'EXÉCUTION'}"
    puts "Issues supprimées: #{deleted_count}"
    puts "Issues créées: #{created_count}"
    puts "Issues extraites du plan.md: #{issues.length}"
    puts "=" * 80

    disconnect_db
  rescue Interrupt
    puts "\n\n⚠️  Opération annulée par l'utilisateur"
    disconnect_db
    exit(0)
  end
end

if __FILE__ == $0
  recreator = IssueRecreator.new(ARGV)
  recreator.run
end
