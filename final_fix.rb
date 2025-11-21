#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Removing all references to new files..."

# Files to completely remove first
filenames = [
  'WorkoutStateManager.swift',
  'WorkoutHistoryView.swift',
  'WorkoutDetailView.swift',
  'WorkoutSummaryView.swift',
  'StateRestorationTests.swift'
]

#Remove from all targets
project.targets.each do |t|
  t.source_build_phase.files.each do |bf|
    if bf.file_ref && bf.file_ref.path && filenames.any? { |fn| bf.file_ref.path.include?(fn) }
      puts "  Removing #{bf.file_ref.path} from #{t.name}"
      bf.remove_from_project
    end
  end
end

# Remove all file references
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference) && item.path && filenames.any? { |fn| item.path.include?(fn) }
    puts "  Removing file reference: #{item.path}"
    item.remove_from_project
  end
end

puts "\nAdding files with correct paths..."

# Helper function
def find_group(project, path_components)
  current = project.main_group

  path_components.each do |component|
    found = current.children.find do |child|
      child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == component
    end

    return nil unless found
    current = found
  end

  current
end

# Files to add - just the filename in the path field
files_to_add = [
  { filename: 'WorkoutStateManager.swift', group_path: ['Sources', 'Services'] },
  { filename: 'WorkoutHistoryView.swift', group_path: ['Sources', 'UI', 'Screens'] },
  { filename: 'WorkoutDetailView.swift', group_path: ['Sources', 'UI', 'Screens'] },
  { filename: 'WorkoutSummaryView.swift', group_path: ['Sources', 'UI', 'Screens'] }
]

files_to_add.each do |file_info|
  group = find_group(project, file_info[:group_path])

  unless group
    puts "  ⚠️  Group not found: #{file_info[:group_path].join('/')}"
    next
  end

  # Create file reference with JUST the filename
  file_ref = group.new_reference(file_info[:filename])
  file_ref.source_tree = '<group>'

  puts "  ✅ Added #{file_info[:filename]} to #{file_info[:group_path].join('/')}"

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
end

# Add test file
test_target = project.targets.find { |t| t.name.include?('Tests') && !t.name.include?('UI') }

if test_target
  puts "\nAdding StateRestorationTests.swift..."

  test_group = find_group(project, ['Tests', 'DomainTests'])

  if test_group
    file_ref = test_group.new_reference('StateRestorationTests.swift')
    file_ref.source_tree = '<group>'

    puts "  ✅ Added StateRestorationTests.swift to Tests/DomainTests"
    test_target.source_build_phase.add_file_reference(file_ref)
  else
    puts "  ⚠️  Test group not found"
  end
end

puts "\nSaving project..."
project.save

puts "✅ Done!"
