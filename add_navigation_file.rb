#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the Sources/UI group
ui_group = project.main_group.find_subpath('Sources/UI')

# Create Navigation group if it doesn't exist
navigation_group = ui_group['Navigation'] || ui_group.new_group('Navigation', 'Sources/UI/Navigation')

# Add the AppNavigationState.swift file
file_path = 'Sources/UI/Navigation/AppNavigationState.swift'
file_ref = navigation_group.new_file(file_path)

# Add file to target
target.add_file_references([file_ref])

# Save the project
project.save

puts "Added AppNavigationState.swift to project"
