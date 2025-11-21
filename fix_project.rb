#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'WorkoutTimer.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

puts "Cleaning up duplicate file references..."

# Files to check
filenames = [
  'WorkoutStateManager.swift',
  'WorkoutHistoryView.swift',
  'WorkoutDetailView.swift',
  'WorkoutSummaryView.swift',
  'StateRestorationTests.swift'
]

# Remove duplicates from build phase
filenames.each do |filename|
  build_files = target.source_build_phase.files.select do |bf|
    bf.file_ref && bf.file_ref.path && bf.file_ref.path.include?(filename)
  end

  if build_files.count > 1
    puts "  Found #{build_files.count} references to #{filename}, removing duplicates..."
    # Keep only the first one
    build_files[1..-1].each do |bf|
      bf.remove_from_project
      puts "    Removed duplicate"
    end
  elsif build_files.count == 1
    puts "  ✓ #{filename} - single reference (good)"
  else
    puts "  ⚠  #{filename} - not found in build phase"
  end
end

# Also check test target
test_target = project.targets.find { |t| t.name.include?('Tests') && !t.name.include?('UI') }

if test_target
  puts "\nChecking test target: #{test_target.name}"

  test_files = test_target.source_build_phase.files.select do |bf|
    bf.file_ref && bf.file_ref.path && bf.file_ref.path.include?('StateRestorationTests.swift')
  end

  if test_files.count > 1
    puts "  Found #{test_files.count} references to StateRestorationTests.swift, removing duplicates..."
    test_files[1..-1].each do |bf|
      bf.remove_from_project
      puts "    Removed duplicate"
    end
  elsif test_files.count == 1
    puts "  ✓ StateRestorationTests.swift - single reference (good)"
  end
end

puts "\nSaving project..."
project.save

puts "✅ Done! Project cleaned up."
