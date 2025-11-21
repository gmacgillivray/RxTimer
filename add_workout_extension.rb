#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the Persistence group
sources_group = project.main_group.find_subpath('Sources')
persistence_group = sources_group['Persistence']

# Add the file in the Persistence group
file_ref = persistence_group.new_reference('Workout+DisplayData.swift')
file_ref.set_source_tree('<group>')

# Add file to target
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "Added Workout+DisplayData.swift to Persistence group"
