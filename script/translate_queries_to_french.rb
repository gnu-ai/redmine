#!/usr/bin/env ruby
# frozen_string_literal: true

# Script pour traduire les noms des queries du turc vers le français

require 'pg'

class QueryTranslator
  TRANSLATIONS = {
    "Bana atanmış işler" => "Tâches assignées",
    "Rapor edilmiş işler" => "Issues rapportés",
    "Güncellenen işler" => "Issues mises à jour",
    "İzlenmiş işler" => "Issues suivis",
    "Projelerim" => "Mes projets",
    "Yer işaretlerim" => "Mes signets",
    "Harcanan zaman" => "Temps passé"
  }.freeze

  DEFAULT_CONFIG = {
    host: '127.0.0.1',
    database: 'redmine',
    username: 'redmine',
    password: 'JusteVivreHeureuse2029',
    port: 5432
  }.freeze

  def initialize
    @connection = nil
  end

  def connect_db
    @connection = PG.connect(
      host: DEFAULT_CONFIG[:host],
      dbname: DEFAULT_CONFIG[:database],
      user: DEFAULT_CONFIG[:username],
      password: DEFAULT_CONFIG[:password],
      port: DEFAULT_CONFIG[:port]
    )
  rescue PG::Error => e
    puts "❌ Erreur de connexion: #{e.message}"
    exit(1)
  end

  def disconnect_db
    @connection&.close
  end

  def translate_queries
    puts "\n" + "=" * 80
    puts "TRADUCTION DES QUERIES TURC → FRANÇAIS"
    puts "=" * 80
    
    TRANSLATIONS.each do |turkish_name, french_name|
      # Trouver la query avec ce nom
      result = @connection.exec_params(
        "SELECT id FROM queries WHERE name = $1",
        [turkish_name]
      )
      
      if result.count == 1
        query_id = result.first['id']
        puts "Trouvée: ID #{query_id} - '#{turkish_name}' → '#{french_name}'"
        
        # Mettre à jour le nom
        @connection.exec_params(
          "UPDATE queries SET name = $1 WHERE id = $2",
          [french_name, query_id]
        )
        puts "  ✅ Mise à jour"
      else
        puts "⚠️  Introuvable: '#{turkish_name}' (#{result.count} résultats)"
      end
    end
    
    puts "\n✅ Toutes les traductions ont été appliquées"
  end

  def check_queries
    puts "\n" + "=" * 80
    puts "VÉRIFICATION DES QUERIES ACTUELLES"
    puts "=" * 80
    
    result = @connection.exec("SELECT id, name FROM queries ORDER BY id")
    
    result.each do |row|
      id = row['id']
      name = row['name']
      
      # Vérifier si c'est encore en turc
      turkish_keys = TRANSLATIONS.keys
      is_turkish = turkish_keys.any? { |key| name.include?(key) || key.include?(name) }
      
      status = is_turkish ? "❌ TURC" : "✅ FRANÇAIS"
      puts "ID #{id}: #{status} | #{name}"
    end
  end

  def run
    connect_db
    
    # D'abord vérifier
    check_queries
    
    puts "\nVoulez-vous traduire ces queries en français? (y/n)"
    answer = gets.chomp.downcase
    
    if answer == 'y' || answer == 'yes'
      translate_queries
      # Vérifier à nouveau
      puts "\n"
      check_queries
    else
      puts "Opération annulée"
    end
    
    disconnect_db
  rescue Interrupt
    puts "\n\n⚠️  Opération annulée"
    disconnect_db
    exit(0)
  end
end

if __FILE__ == $0
  translator = QueryTranslator.new
  translator.run
end
