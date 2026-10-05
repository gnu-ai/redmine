# Script pour importer toutes les tâches depuis les fichiers PLAN.md

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

# Obtenir les références Redmine
projects = Project.all.index_by(&:name)
trackers = Tracker.all.index_by(&:name)
statuses = IssueStatus.all.index_by(&:name)
priorities = IssuePriority.all.index_by(&:name)

# Utiliser le tracker "Özellik" (ID: 2) = Feature
# Utiliser le statut "Yeni" (ID: 1) = New  
# Utiliser la priorité "Normal" (ID: 2)
# Utiliser l'utilisateur admin (ID: 1)

tracker = trackers['Özellik'] || trackers.values.first
status = statuses['Yeni'] || statuses.values.first
priority = priorities['Normal'] || priorities.values.first
author = User.find_by_admin(true) || User.first

total_imported = 0
total_errors = []

project_files.each do |project_name, filepath|
  next unless File.exist?(filepath)
  
  project = projects[project_name]
  if project.nil?
    puts "✗ Projet '#{project_name}' non trouvé dans Redmine"
    next
  end
  
  puts "Import des tâches pour le projet: #{project_name} (ID: #{project.id})"
  
  tasks = parse_plan_file(filepath)
  puts "  Tâches extraites: #{tasks.size}"
  
  imported_count = 0
  errors = []
  
  tasks.each do |task|
    begin
      # Nettoyer le sujet pour Redmine (limite 255 caractères)
      subject = task[:description].truncate(255)
      
      # Créer la tâche
      issue = Issue.new(
        project: project,
        tracker: tracker,
        subject: subject,
        description: task[:full_description],
        status: status,
        priority: priority,
        author: author
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
  
  total_imported += imported_count
  total_errors += errors
end

puts "\n" + "="*50
puts "IMPORTATION TERMINÉE"
puts "Total des tâches importées: #{total_imported}"
unless total_errors.empty?
  puts "Total des erreurs: #{total_errors.size}"
  total_errors.each { |e| puts "  #{e}" }
end
puts "="*50