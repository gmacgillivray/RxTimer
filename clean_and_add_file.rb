#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Remove all existing broken references to AppNavigationState.swift
all_files = []
project.files.each do |file|
  if file.path && file.path.include?('AppNavigationState.swift')
    puts "Removing reference: #{file.path}"
    all_files << file
  end
end

all_files.each { |f| f.remove_from_project }

# Find the Screens group
sources_group = project.main_group.find_subpath('Sources')
ui_group = sources_group['UI']
screens_group = ui_group['Screens']

# Add the file in the Screens group
file_ref = screens_group.new_reference('AppNavigationState.swift')
file_ref.set_source_tree('<group>')

# Add file to target
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "Added AppNavigationState.swift to Screens group"
