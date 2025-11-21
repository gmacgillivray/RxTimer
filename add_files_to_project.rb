#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Files to add with their group paths
files_to_add = [
  {
    path: 'Sources/Services/WorkoutStateManager.swift',
    group_path: ['Sources', 'Services']
  },
  {
    path: 'Sources/UI/Screens/WorkoutHistoryView.swift',
    group_path: ['Sources', 'UI', 'Screens']
  },
  {
    path: 'Sources/UI/Screens/WorkoutDetailView.swift',
    group_path: ['Sources', 'UI', 'Screens']
  },
  {
    path: 'Sources/UI/Screens/WorkoutSummaryView.swift',
    group_path: ['Sources', 'UI', 'Screens']
  }
]

test_files = [
  {
    path: 'Tests/DomainTests/StateRestorationTests.swift',
    group_path: ['Tests', 'DomainTests']
  }
]

puts "Adding files to Xcode project..."

# Function to find or create group
def find_or_create_group(project, group_path)
  current_group = project.main_group

  group_path.each do |group_name|
    # Try to find existing group
    found_group = current_group.children.find { |child| child.display_name == group_name && child.is_a?(Xcodeproj::Project::Object::PBXGroup) }

    if found_group
      current_group = found_group
    else
      # Create new group
      puts "  Creating group: #{group_name}"
      new_group = current_group.new_group(group_name)
      current_group = new_group
    end
  end

  current_group
end

# Add main source files
files_to_add.each do |file_info|
  file_path = file_info[:path]

  # Check if file exists on disk
  unless File.exist?(file_path)
    puts "  ⚠️  File not found: #{file_path}"
    next
  end

  # Find or create the group
  group = find_or_create_group(project, file_info[:group_path])

  # Check if file already exists in project
  existing_file = group.files.find { |f| f.path == File.basename(file_path) }

  if existing_file
    puts "  ⏭️  File already in project: #{file_path}"
    # Remove it first if it exists but with wrong path
    if existing_file.real_path.to_s != File.absolute_path(file_path)
      puts "  🔄 Removing incorrect reference..."
      existing_file.remove_from_project
      existing_file = nil
    end
  end

  unless existing_file
    # Add file reference using absolute path
    file_ref = group.new_file(File.absolute_path(file_path))
    puts "  ✅ Added: #{file_path}"

    # Add to build phase (compile sources)
    target.source_build_phase.add_file_reference(file_ref)
  end
end

# Add test files to test target
test_target = project.targets.find { |t| t.name.include?('Tests') && !t.name.include?('UI') }

if test_target
  puts "\nAdding test files to test target: #{test_target.name}"

  test_files.each do |file_info|
    file_path = file_info[:path]

    # Check if file exists on disk
    unless File.exist?(file_path)
      puts "  ⚠️  File not found: #{file_path}"
      next
    end

    # Find or create the group
    group = find_or_create_group(project, file_info[:group_path])

    # Check if file already exists in project
    existing_file = group.files.find { |f| f.path == File.basename(file_path) }

    if existing_file
      puts "  ⏭️  File already in project: #{file_path}"
      # Remove it first if it exists but with wrong path
      if existing_file.real_path.to_s != File.absolute_path(file_path)
        puts "  🔄 Removing incorrect reference..."
        existing_file.remove_from_project
        existing_file = nil
      end
    end

    unless existing_file
      # Add file reference using absolute path
      file_ref = group.new_file(File.absolute_path(file_path))
      puts "  ✅ Added: #{file_path}"

      # Add to test target's build phase
      test_target.source_build_phase.add_file_reference(file_ref)
    end
  end
else
  puts "\n⚠️  Test target not found, skipping test files"
end

# Save the project
puts "\nSaving project..."
project.save

puts "✅ Done! Files added to Xcode project."
puts "\nNext step: Build the project with:"
puts "  xcodebuild -scheme WorkoutTimer -destination 'platform=iOS Simulator,name=iPhone 17' build"
