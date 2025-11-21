#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the Components group
sources_group = project.main_group.find_subpath('Sources')
ui_group = sources_group['UI']
components_group = ui_group['Components']

# Add the file in the Components group
file_ref = components_group.new_reference('WorkoutSummaryContentView.swift')
file_ref.set_source_tree('<group>')

# Add file to target
target.source_build_phase.add_file_reference(file_ref)

# Save the project
project.save

puts "Added WorkoutSummaryContentView.swift to Components group"
