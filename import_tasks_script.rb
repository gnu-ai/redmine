#!/usr/bin/env ruby

# Script pour importer les tâches depuis les fichiers PLAN.md dans Redmine
# Doit être exécuté avec : RAILS_ENV=production sudo -u redmine bundle exec ruby /tmp/import_tasks_script.rb

require_relative '/var/www/redmine-7.0.1/config/environment'

# Désactiver le chargement du listener de développement
if Rails.env.development?
  ActiveSupport::EventedFileUpdateChecker.send(:define_singleton_method, :initialize) do |*args|
    # No-op pour éviter le chargement de listen
  end
end

# Vérifier la connexion à la base de données
begin
  ActiveRecord::Base.connection.test
  puts "✓ Connexion à la base de données établie"
rescue => e
  puts "✗ Erreur de connexion: #{e.message}"
  exit 1
end

# Obtenir les informations nécessaires
def get_redmine_info
  @projects ||= Project.all.index_by(&:name)
  @trackers ||= Tracker.all.index_by(&:name)
  @statuses ||= IssueStatus.all.index_by(&:name)
  @priorities ||= IssuePriority.all.index_by(&:name)
  @users ||= User.all.index_by(&:login)
  
  # Trouver l'utilisateur admin/redmine
  @author ||= @users.values.find { |u| u.admin? } || @users.values.first
end

# Fonction pour parser un fichier PLAN.md
def parse_plan_file(filepath)
  content = File.read(filepath)
  tasks = []
  current_phase = nil
  current_section = nil
  
  lines = content.split("\n")
  
  lines.each_with_index do |line, index|
    # Détection des phases (## X. ou ## X - ou ## X —)
    if line.match(/^##\s*(\d+)\s*[.–—]\s*(.+)/)
      phase_num = $1
      phase_name = $2.strip
      current_phase = "Phase #{phase_num}: #{phase_name}"
      current_section = nil
      next
    end
    
    # Détection des sous-sections
    if line.match(/^###\s+(.+)/)
      current_section = $1.strip
      next
    end
    
    if line.match(/^####\s+(.+)/)
      current_section = $1.strip
      next
    end
    
    # Détection des listes numérotées
    if line.match(/^\s*(\d+)\s*[.)–—]\s*(.+)/)
      task_desc = $2.strip
      task_desc = task_desc.gsub(/^[\*"-]\s*/, '')
      
      full_description = ""
      full_description += "**Phase:** #{current_phase}\n\n" if current_phase
      full_description += "**Section:** #{current_section}\n\n" if current_section
      full_description += task_desc
      
      tasks << {
        phase: current_phase,
        section: current_section,
        description: task_desc,
        full_description: full_description
      }
    end
    
    # Détection des listes à puces (mais pas dans les tables ou le code)
    if line.match(/^\s*[-*+]\s+(.+)/) && !line.include?('|') && !line.start_with?('```') && !line.start_with?('    ')
      task_desc = $1.strip
      
      full_description = ""
      full_description += "**Phase:** #{current_phase}\n\n" if current_phase
      full_description += "**Section:** #{current_section}\n\n" if current_section
      full_description += task_desc
      
      tasks << {
        phase: current_phase,
        section: current_section,
        description: task_desc,
        full_description: full_description
      }
    end
  end
  
  tasks
end

# Mapper les noms de projets GitHub aux noms de projets Redmine
project_files = {
  'neuron translator' => '/tmp/neuron-translator-PLAN.md',
  'Data Base Translator' => '/tmp/data-base-translator-PLAN.md',
  'Inference Translator' => '/tmp/inference-translator-PLAN.md',
  'Orchestrator Translator' => '/tmp/orchestrator-translator-PLAN.md'
}

puts "Chargement des informations Redmine..."
get_redmine_info

puts "\nProjets trouvés:"
@projects.each do |name, project|
  puts "  #{project.id}: #{name}"
end

puts "\nTrackers trouvés:"
@trackers.each do |name, tracker|
  puts "  #{tracker.id}: #{name}"
end

puts "\nStatuts trouvés:"
@statuses.each do |name, status|
  puts "  #{status.id}: #{name}"
end

# Main import function
def import_tasks_for_project(project_name, filepath)
  project = @projects[project_name]
  return nil, "Projet '#{project_name}' non trouvé" unless project
  
  tracker = @trackers['Feature'] || @trackers.values.first
  status = @statuses['New'] || @statuses.values.first
  priority = @priorities['Normal'] || @priorities.values.first
  
  puts "\nImport des tâches pour le projet: #{project_name} (ID: #{project.id})"
  
  tasks = parse_plan_file(filepath)
  puts "  Tâches extraites: #{tasks.size}"
  
  imported_count = 0
  errors = []
  
  tasks.each do |task|
    begin
      issue = Issue.new(
        project: project,
        tracker: tracker,
        subject: task[:description].truncate(255), # Redmine limite à 255 caractères
        description: task[:full_description],
        status: status,
        priority: priority,
        author: @author
      )
      
      if issue.save
        imported_count += 1
        print "." if imported_count % 10 == 0
      else
        errors << "Erreur pour '#{task[:description][0..50]}': #{issue.errors.full_messages.join(', ')}"
      end
    rescue => e
      errors << "Exception pour '#{task[:description][0..50]}': #{e.message}"
    end
  end
  
  puts "  Tâches importées: #{imported_count}/#{tasks.size}"
  errors.each { |e| puts "    ✗ #{e}" } unless errors.empty?
  
  [imported_count, errors]
end

# Importer les tâches pour tous les projets
total_imported = 0
total_errors = []

project_files.each do |project_name, filepath|
  next unless File.exist?(filepath)
  
  imported, errors = import_tasks_for_project(project_name, filepath)
  if imported
    total_imported += imported
    total_errors += errors
  end
end

puts "\n" + "="*50
puts "IMPORTATION TERMINÉE"
puts "Total des tâches importées: #{total_imported}"
puts "Total des erreurs: #{total_errors.size}" unless total_errors.empty?
puts "="*50