#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Remove any existing broken references
target.source_build_phase.files.each do |file|
  if file.file_ref && file.file_ref.path && file.file_ref.path.include?('AppNavigationState.swift')
    puts "Removing broken reference: #{file.file_ref.path}"
    file.remove_from_project
  end
end

# Find the Sources/UI group
sources_group = project.main_group.find_subpath('Sources')
ui_group = sources_group['UI']

# Get or create Navigation group with correct path
navigation_group = ui_group['Navigation']
if navigation_group.nil?
  navigation_group = ui_group.new_group('Navigation')
  navigation_group.set_source_tree('<group>')
  navigation_group.set_path('Navigation')
end

# Add the file with relative path from the group
file_ref = navigation_group.new_reference('AppNavigationState.swift')
file_ref.set_source_tree('<group>')

# Add file to target
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "Fixed AppNavigationState.swift reference in project"
