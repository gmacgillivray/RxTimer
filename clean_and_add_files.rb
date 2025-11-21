#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Step 1: Removing ALL references to new files..."

# Files to completely remove first
filenames = [
  'WorkoutStateManager.swift',
  'WorkoutHistoryView.swift',
  'WorkoutDetailView.swift',
  'WorkoutSummaryView.swift'
]

# Remove all references from main target
filenames.each do |filename|
  # Remove from build phase
  target.source_build_phase.files.each do |bf|
    if bf.file_ref && bf.file_ref.path && bf.file_ref.path.include?(filename)
      puts "  Removing #{filename} from build phase"
      bf.remove_from_project
    end
  end

  # Remove file references from all groups
  project.main_group.recursive_children.each do |item|
    if item.is_a?(Xcodeproj::Project::Object::PBXFileReference) && item.path && item.path.include?(filename)
      puts "  Removing file reference: #{item.path}"
      item.remove_from_project
    end
  end
end

# Handle test files
test_target = project.targets.find { |t| t.name.include?('Tests') && !t.name.include?('UI') }

if test_target
  puts "\nRemoving StateRestorationTests.swift from test target..."

  test_target.source_build_phase.files.each do |bf|
    if bf.file_ref && bf.file_ref.path && bf.file_ref.path.include?('StateRestorationTests.swift')
      puts "  Removing from build phase"
      bf.remove_from_project
    end
  end

  project.main_group.recursive_children.each do |item|
    if item.is_a?(Xcodeproj::Project::Object::PBXFileReference) && item.path && item.path.include?('StateRestorationTests.swift')
      puts "  Removing file reference: #{item.path}"
      item.remove_from_project
    end
  end
end

puts "\nStep 2: Adding files with correct paths..."

# Helper function to find group by path components
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

# Add files to correct groups
files_to_add = {
  'Sources/Services/WorkoutStateManager.swift' => ['Sources', 'Services'],
  'Sources/UI/Screens/WorkoutHistoryView.swift' => ['Sources', 'UI', 'Screens'],
  'Sources/UI/Screens/WorkoutDetailView.swift' => ['Sources', 'UI', 'Screens'],
  'Sources/UI/Screens/WorkoutSummaryView.swift' => ['Sources', 'UI', 'Screens']
}

files_to_add.each do |file_path, group_path|
  group = find_group(project, group_path)

  unless group
    puts "  ⚠️  Group not found for: #{group_path.join('/')}"
    next
  end

  # Create file reference with relative path
  file_ref = group.new_reference(file_path)
  file_ref.source_tree = '<group>'

  puts "  ✅ Added: #{file_path}"

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)
end

# Add test file
if test_target
  puts "\nAdding StateRestorationTests.swift to test target..."

  test_group = find_group(project, ['Tests', 'DomainTests'])

  if test_group
    file_ref = test_group.new_reference('Tests/DomainTests/StateRestorationTests.swift')
    file_ref.source_tree = '<group>'

    puts "  ✅ Added: StateRestorationTests.swift"
    test_target.source_build_phase.add_file_reference(file_ref)
  else
    puts "  ⚠️  Test group not found"
  end
end

puts "\nStep 3: Saving project..."
project.save

puts "✅ Done! Project should now build correctly."
