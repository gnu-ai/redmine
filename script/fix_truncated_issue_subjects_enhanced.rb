#!/usr/bin/env ruby
# frozen_string_literal: true

# Script ENHANCED de correction des sujets d'issues tronqués dans Redmine
# Ce script peut essayer de récupérer les sujets originaux à partir des journaux
#
# Utilisation : ruby script/fix_truncated_issue_subjects_enhanced.rb [options]
#
# Options :
#   --check, -c          Vérifier seulement (ne pas corriger)
#   --fix, -f           Corriger les sujets tronqués
#   --recover, -r       Essayer de récupérer à partir des journaux
#   --dry-run           Simulation (affiche ce qui serait corrigé)
#   --length LENGTH     Longueur maximale pour considérer comme tronqué (default: 60)
#   --limit N           Limite le nombre d'issues à traiter
#   --verbose, -v       Mode verbeux
#   --help, -h          Affiche cette aide

require 'optparse'
require 'pg'

class EnhancedTruncatedIssueFixer
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
      recover: false,
      dry_run: false,
      max_length: 60,
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

      opts.on("--recover", "-r", "Essayer de récupérer à partir des journaux") do |v|
        options[:recover] = v
      end

      opts.on("--dry-run", "Simulation (affiche ce qui serait corrigé)") do |v|
        options[:dry_run] = v
      end

      opts.on("--length LENGTH", Integer, "Longueur maximale pour considérer comme tronqué (default: 60)") do |v|
        options[:max_length] = v
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

    if !options[:check_only] && !options[:fix] && !options[:recover] && !options[:dry_run] && !options[:show_help]
      options[:check_only] = true
    end

    options
  end

  def show_help
    puts <<~HELP
      Script ENHANCED de correction des sujets d'issues tronqués dans Redmine

      Utilisation : ruby #{__FILE__} [options]

      Options :
        --check, -c          Vérifier seulement (ne pas corriger)
        --fix, -f           Corriger les sujets tronqués
        --recover, -r       Essayer de récupérer à partir des journaux
        --dry-run           Simulation (affiche ce qui serait corrigé)
        --length LENGTH     Longueur maximale pour considérer comme tronqué (default: 60)
        --limit N           Limite le nombre d'issues à traiter
        --verbose, -v       Mode verbeux
        --help, -h          Affiche cette aide

      Exemples :
        ruby #{__FILE__} --check --length 60 --limit 10
        ruby #{__FILE__} --recover --limit 5 --verbose
        ruby #{__FILE__} --fix --dry-run

      La récupération à partir des journaux peut trouver les sujets originaux
      si les issues ont été modifiées et que l'ancien sujet était dans les journaux.
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

  def execute_query(query)
    result = []
    @connection.exec(query) do |pg_result|
      pg_result.each do |row|
        result << row
      end
    end
    result
  rescue PG::Error => e
    puts "❌ Erreur lors de l'exécution de la requête: #{e.message}"
    []
  end

  def find_truncated_issues
    query = <<~SQL
      SELECT i.id, i.subject, i.tracker_id, i.project_id, i.created_on, i.updated_on
      FROM issues i
      WHERE LENGTH(i.subject) <= #{options[:max_length]}
         OR i.subject LIKE '%...'
      ORDER BY LENGTH(i.subject) ASC, i.id ASC
    SQL
    
    if options[:limit]
      query += " LIMIT #{options[:limit]}"
    end

    issues = execute_query(query)
    issues.map do |row|
      {
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

  def find_original_subject_from_journals(issue_id)
    # Cherche dans les journaux l'ancien sujet avant le tronquage
    query = <<~SQL
      SELECT j.id, j.notes, j.created_on,
             d.id as detail_id, d.prop_key, d.old_value, d.value
      FROM journals j
      LEFT JOIN journal_details d ON d.journal_id = j.id
      WHERE j.journalized_type = 'Issue' AND j.journalized_id = #{issue_id}
      ORDER BY j.created_on ASC, j.id ASC
    SQL
    
    journals = execute_query(query)
    
    # Recherche le dernier changement de sujet avant le tronquage
    original_subject = nil
    journals.each do |journal|
      if journal['prop_key'] == 'subject' && journal['old_value']
        old_value = journal['old_value']
        # Si l'ancienne valeur est plus longue que l'actuelle, c'est probablement l'original
        if old_value.length > options[:max_length]
          original_subject = old_value
          break
        end
      end
    end
    
    original_subject
  end

  def display_issues_with_recovery(issues)
    puts "\n" + "=" * 120
    puts "ISSUES AVEC SUJETS POTENTIELLEMENT TRONQUÉS (avec récupération)"
    puts "=" * 120
    puts "Trouvées: #{issues.length} issues"
    puts "Limite de longueur: #{options[:max_length]} caractères"
    puts "-" * 120
    
    recovery_count = 0
    
    issues.each_with_index do |issue, index|
      puts "\n#{index + 1}. ID: #{issue[:id]} | Longueur: #{issue[:length]} | Projet: #{issue[:project_id]}"
      puts "   Sujet ACTUEL: '#{issue[:subject]}'"
      puts "   Créé: #{issue[:created_on]} | Modifié: #{issue[:updated_on]}"
      
      # Essayer de récupérer le sujet original
      original_subject = find_original_subject_from_journals(issue[:id])
      
      if original_subject && original_subject != issue[:subject]
        puts "   🟢 SUJET ORIGINAL TROUVÉ: '#{original_subject}' (longueur: #{original_subject.length})"
        recovery_count += 1
      else
        puts "   ❌ Aucun sujet original trouvé dans les journaux"
      end
      
      puts "-" * 120
    end
    
    puts "\n📊 STATISTIQUES:"
    puts "   - Issues vérifiées: #{issues.length}"
    puts "   - Sujets originaux récupérés: #{recovery_count}"
    puts "   - Pourcentages: #{recovery_count > 0 ? (recovery_count.to_f / issues.length * 100).round(2) : 0}%"
    
    if recovery_count > 0 && issues.length > recovery_count
      puts "\n⚠️  Certains sujets n'ont pas pu être récupérés automatiquement."
    elsif recovery_count == 0
      puts "\n❌ Aucun sujet original trouvé. Les données peuvent avoir été définitivement perdues."
    else
      puts "\n✅ Tous les sujets originaux ont été récupérés !"
    end
  end

  def generate_recovery_script(issues)
    puts "\n" + "=" * 100
    puts "GÉNÉRATION DU SCRIPT SQL DE CORRECTION"
    puts "=" * 100
    
    sql_script = "-- Script SQL généré par fix_truncated_issue_subjects_enhanced.rb\n"
    sql_script += "-- Date: #{Time.now}\n"
    sql_script += "-- Ce script corrige les sujets d'issues tronqués\n\n"
    
    update_count = 0
    
    issues.each do |issue|
      original_subject = find_original_subject_from_journals(issue[:id])
      
      if original_subject && original_subject != issue[:subject]
        # Échapper les apostrophes pour SQL
        escaped_subject = original_subject.gsub("'", "''")
        
        sql_script += "-- Issue ID: #{issue[:id]} - Longueur actuelle: #{issue[:length]}, Nouvelle longueur: #{original_subject.length}\n"
        sql_script += "UPDATE issues SET subject = '#{escaped_subject}' WHERE id = #{issue[:id]};\n\n"
        update_count += 1
      end
    end
    
    sql_script += "-- Total: #{update_count} issues à corriger\n"
    
    filename = "fix_issue_subjects_#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql"
    File.write(filename, sql_script)
    
    puts "✅ Script SQL généré: #{filename}"
    puts "   Contient #{update_count} instructions UPDATE"
    puts ""
    puts "Pour exécuter ce script :"
    puts "   PGPASSWORD='JusteVivreHeureuse2029' psql -h 127.0.0.1 -U redmine -d redmine -f #{filename}"
    puts ""
    puts "⚠️  AVANT d'exécuter :"
    puts "   - Faites une sauvegarde de la base de données"
    puts "   - Vérifiez le contenu du script SQL"
    puts "   - Testez sur une instance de développement d'abord"
  end

  def run
    if options[:show_help]
      show_help
      return
    end

    puts "\n" + "=" * 100
    puts "SCRIPT ENHANCED DE CORRECTION DES SUJETS D'ISSUES TRONQUÉS"
    puts "=" * 100
    
    connect_db

    if options[:check_only]
      puts "\n🔍 Mode: VÉRIFICATION SEULEMENT"
      issues = find_truncated_issues
      
      if options[:recover]
        display_issues_with_recovery(issues)
      else
        # Affichage simple
        puts "\nTrouvées: #{issues.length} issues avec sujets potentiellement tronqués"
        issues.each_with_index do |issue, index|
          puts "#{index + 1}. ID: #{issue[:id]} | #{issue[:length]} chars | #{issue[:subject][0..50]}#{'...' if issue[:subject].length > 50}"
        end
      end
      
      # Statistiques par longueur
      lengths = issues.group_by { |i| i[:length] }.map { |k, v| [k, v.length] }.sort
      puts "\n📊 Distribution par longueur:"
      lengths.each do |length, count|
        puts "   #{length} caractères: #{count} issues"
      end
      
    elsif options[:fix] || options[:recover]
      puts "\n🔧 Mode: RÉCUPÉRATION ET CORRECTION"
      puts "   Dry run: #{options[:dry_run] ? 'OUI' : 'NON'}"
      puts "   Récupération: #{options[:recover] ? 'OUI' : 'NON'}"
      
      issues = find_truncated_issues
      
      if options[:recover]
        display_issues_with_recovery(issues)
        
        unless options[:dry_run]
          puts "\nVoulez-vous générer un script SQL pour corriger ces issues? (y/n)"
          answer = gets.chomp.downcase
          if answer == 'y' || answer == 'yes'
            generate_recovery_script(issues)
          end
        else
          puts "\n📝 Simulation terminée. Aucune modification appliquée."
        end
      else
        display_issues_with_recovery(issues)
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
  fixer = EnhancedTruncatedIssueFixer.new
  fixer.run
end
