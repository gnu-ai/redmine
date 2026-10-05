#!/usr/bin/env ruby
# frozen_string_literal: true

# Script de correction des sujets d'issues tronqués dans Redmine
# Utilisation : ruby script/fix_truncated_issue_subjects.rb [options]
#
# Options :
#   --check, -c          Vérifier seulement (ne pas corriger)
#   --fix, -f           Corriger les sujets tronqués
#   --dry-run           Simulation (affiche ce qui serait corrigé)
#   --length LENGTH     Longueur maximale pour considérer comme tronqué (default: 60)
#   --ends-with TEXT    Texte de fin pour identifier les tronqués (default: "...")
#   --limit N           Limite le nombre d'issues à traiter
#   --verbose, -v       Mode verbeux
#   --help, -h          Affiche cette aide

require 'optparse'
require 'pg'

class TruncatedIssueFixer
  DEFAULT_CONFIG = {
    host: '127.0.0.1',
    database: 'redmine',
    username: 'redmine',
    password: 'JusteVivreHeureuse2029',
    port: 5432
  }.freeze

  attr_reader :db_config, :options

  def initialize(db_config = DEFAULT_CONFIG, args = [])
    @db_config = db_config
    @options = parse_options(args)
    @connection = nil
  end

  def parse_options(args)
    options = {
      check_only: false,
      fix: false,
      dry_run: false,
      max_length: 60,
      ends_with: '...',
      limit: nil,
      verbose: false,
      show_help: false
    }

    parser = OptionParser.new do |opts|
      opts.banner = "Utilisation: ruby #{__FILE__} [options]"

      opts.separator ""
      opts.separator "Options :"

      opts.on("--check", "-c", "Vérifier seulement (ne pas corriger)") do |v|
        options[:check_only] = v
      end

      opts.on("--fix", "-f", "Corriger les sujets tronqués") do |v|
        options[:fix] = v
      end

      opts.on("--dry-run", "Simulation (affiche ce qui serait corrigé)") do |v|
        options[:dry_run] = v
      end

      opts.on("--length LENGTH", Integer, "Longueur maximale pour considérer comme tronqué (default: 60)") do |v|
        options[:max_length] = v
      end

      opts.on("--ends-with TEXT", "Texte de fin pour identifier les tronqués (default: \"...\")") do |v|
        options[:ends_with] = v
      end

      opts.on("--limit N", Integer, "Limite le nombre d'issues à traiter") do |v|
        options[:limit] = v
      end

      opts.on("--verbose", "-v", "Mode verbeux") do |v|
        options[:verbose] = v
      end

      opts.on("--help", "-h", "Affiche cette aide") do |v|
        options[:show_help] = v
      end
    end

    parser.parse!(args)

    if !options[:check_only] && !options[:fix] && !options[:dry_run] && !options[:show_help]
      options[:check_only] = true
    end

    options
  end

  def show_help
    puts <<~HELP
      Script de correction des sujets d'issues tronqués dans Redmine

      Utilisation : ruby #{__FILE__} [options]

      Options :
        --check, -c          Vérifier seulement (ne pas corriger)
        --fix, -f           Corriger les sujets tronqués
        --dry-run           Simulation (affiche ce qui serait corrigé)
        --length LENGTH     Longueur maximale pour considérer comme tronqué (default: 60)
        --ends-with TEXT    Texte de fin pour identifier les tronqués (default: "...")
        --limit N           Limite le nombre d'issues à traiter
        --verbose, -v       Mode verbeux
        --help, -h          Affiche cette aide

      Exemples :
        ruby #{__FILE__} --check --length 60 --limit 10
        ruby #{__FILE__} --fix --dry-run --verbose
        ruby #{__FILE__} --fix --length 100

      Note : Pour la correction, les sujets doivent être modifiés manuellement
            car les données originales tronquées ne sont pas stockées.
    HELP
  end

  def connect_db
    @connection = PG.connect(
      host: db_config[:host],
      dbname: db_config[:database],
      user: db_config[:username],
      password: db_config[:password],
      port: db_config[:port]
    )
    
    if options[:verbose]
      puts "✓ Connecté à la base de données : #{db_config[:database]}@#{db_config[:host]}"
    end
  rescue PG::Error => e
    puts "❌ Erreur de connexion à la base de données: #{e.message}"
    exit(1)
  end

  def disconnect_db
    @connection&.close
  end

  def find_truncated_issues
    query = <<~SQL
      SELECT id, subject, tracker_id, project_id, created_on, updated_on
      FROM issues
      WHERE LENGTH(subject) <= #{options[:max_length]}
         OR subject LIKE '%#{options[:ends_with]}'
      ORDER BY LENGTH(subject) ASC, id ASC
    SQL
    
    if options[:limit]
      query += " LIMIT #{options[:limit]}"
    end

    execute_query(query)
  end

  def find_issues_by_exact_length(length)
    query = "SELECT id, subject, tracker_id, project_id, created_on, updated_on FROM issues WHERE LENGTH(subject) = #{length} ORDER BY id ASC"
    
    if options[:limit]
      query += " LIMIT #{options[:limit]}"
    end

    execute_query(query)
  end

  def execute_query(query)
    result = []
    @connection.exec(query) do |pg_result|
      pg_result.each do |row|
        result << {
          id: row['id'].to_i,
          subject: row['subject'],
          tracker_id: row['tracker_id'],
          project_id: row['project_id'],
          created_on: row['created_on'],
          updated_on: row['updated_on'],
          length: row['subject'].length
        }
      end
    end
    result
  rescue PG::Error => e
    puts "❌ Erreur lors de l'exécution de la requête: #{e.message}"
    []
  end

  def display_issues(issues)
    puts "\n" + "=" * 100
    puts "ISSUES AVEC SUJETS POTENTIELLEMENT TRONQUÉS"
    puts "=" * 100
    puts "Trouvées: #{issues.length} issues"
    puts "Limite de longueur: #{options[:max_length]} caractères"
    puts "Texte de fin: '#{options[:ends_with]}'"
    puts "-" * 100
    
    issues.each_with_index do |issue, index|
      puts "#{index + 1}. ID: #{issue[:id]} | Longueur: #{issue[:length]} | Projet: #{issue[:project_id]} | Tracker: #{issue[:tracker_id]}"
      puts "   Sujet: '#{issue[:subject]}'"
      puts "   Créé: #{issue[:created_on]} | Modifié: #{issue[:updated_on]}"
      puts "-" * 100
    end
    
    if issues.any?
      puts "\n⚠️  ATTENTION: Ces sujets peuvent avoir été tronqués. Les données originales"
      puts "    peuvent ne plus être disponibles pour une restauration automatique."
    else
      puts "\n✅ Aucun sujet tronqué trouvé avec les critères actuels."
    end
  end

  def fix_truncated_issues
    puts "\n" + "=" * 100
    puts "CORRECTION DES SUJETS TRONQUÉS"
    puts "=" * 100
    puts "⚠️  IMPORTANT: La correction automatique n'est pas possible car les données"
    puts "    originales ont été perdues lors du tronquage."
    puts ""
    puts "Pour corriger ces issues, vous devez:"
    puts "1. Consulter les journaux (journals) de chaque issue pour voir les modifications"
    puts "2. Vérifier si le sujet original est dans l'historique"
    puts "3. Mettre à jour manuellement chaque issue via l'interface Redmine"
    puts ""
    puts "Voulez-vous que je génère un rapport CSV pour correction manuelle? (y/n)"
    
    answer = gets.chomp.downcase
    if answer == 'y' || answer == 'yes'
      generate_csv_report
    end
  end

  def generate_csv_report
    issues = find_truncated_issues
    
    csv_file = "truncated_issues_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
    
    File.open(csv_file, 'w') do |file|
      file.puts "id,subject,length,project_id,tracker_id,created_on,updated_on"
      issues.each do |issue|
        file.puts [
          issue[:id],
          issue[:subject].gsub('"', '""'),
          issue[:length],
          issue[:project_id],
          issue[:tracker_id],
          issue[:created_on],
          issue[:updated_on]
        ].join(',')
      end
    end
    
    puts "✅ Rapport CSV généré: #{csv_file}"
    puts "   Vous pouvez ouvrir ce fichier dans un tableur et corriger les sujets manuellement."
  end

  def run
    if options[:show_help]
      show_help
      return
    end

    puts "\n" + "=" * 100
    puts "SCRIPT DE CORRECTION DES SUJETS D'ISSUES TRONQUÉS"
    puts "=" * 100
    
    connect_db

    if options[:check_only]
      puts "\n🔍 Mode: VÉRIFICATION SEULEMENT"
      issues = find_truncated_issues
      display_issues(issues)
      
      [60, 100].each do |length|
        exact_length_issues = find_issues_by_exact_length(length)
        if exact_length_issues.any?
          puts "\n📊 Issues avec exactement #{length} caractères: #{exact_length_issues.length}"
        end
      end
    elsif options[:fix]
      puts "\n🔧 Mode: CORRECTION"
      puts "   Dry run: #{options[:dry_run] ? 'OUI' : 'NON'}"
      
      issues = find_truncated_issues
      display_issues(issues)
      
      unless options[:dry_run]
        fix_truncated_issues
      else
        puts "\n📝 Simulation terminée. Aucune modification appliquée."
      end
    end

    disconnect_db
  rescue Interrupt
    puts "\n\n⚠️  Opération annulée par l'utilisateur"
    disconnect_db
    exit(0)
  end
end

if __FILE__ == $0
  fixer = TruncatedIssueFixer.new
  fixer.run
end
