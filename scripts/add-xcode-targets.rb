#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

# ============================================================================
# CONFIGURATION - All customizable IDs and paths
# ============================================================================

PROJECT_PATH = 'Skip AI.xcodeproj'

# Group configurations
GROUPS = [
  {
    id: 'app',
    name: 'app',
    path: 'dist/app',
    file_patterns: ['*.js', '*.css'],
    targets: ['Skip AI (iOS)', 'Skip AI (macOS)']
  },
  {
    id: 'webext',
    name: 'webext',
    path: 'dist/webext',
    file_patterns: ['*.js'],
    targets: ['Skip AI Extension (iOS)', 'Skip AI Extension (macOS)']
  }
]

# ============================================================================
# IMPLEMENTATION
# ============================================================================

class XcodeGroupManager
  attr_reader :project, :main_group
  
  def initialize(project_path)
    @project = Xcodeproj::Project.open(project_path)
    @main_group = @project.main_group
    @file_refs = {}
  end
  
  # Generic function to populate any group with files
  def populate_group(group_config)
    group_path = group_config[:path]
    group_name = group_config[:name]
    file_patterns = group_config[:file_patterns]
    target_names = group_config[:targets]
    
    puts "Processing group: #{group_name} (#{group_path})"
    
    # Check if directory exists
    unless Dir.exist?(group_path)
      puts "  ⚠️  Directory not found: #{group_path}, skipping"
      return
    end
    
    # Find or create the group
    group = find_or_create_group(group_name, group_path)
    
    # Clear existing children
    group.clear
    
    # Find files matching patterns
    files = find_files(group_path, file_patterns)
    
    if files.empty?
      puts "  ℹ️  No files found in #{group_path}"
      return
    end
    
    puts "  Found #{files.length} file(s)"
    
    # Get targets
    targets = target_names.map { |name| find_target(name) }.compact
    
    if targets.empty?
      puts "  ⚠️  No targets found for: #{target_names.join(', ')}"
      return
    end
    
    # Add files to group and targets
    files.each do |file_path|
      basename = File.basename(file_path)
      
      # Create file reference
      file_ref = group.new_reference(file_path)
      @file_refs[file_path] = file_ref
      
      # Add to target resources
      targets.each do |target|
        add_file_to_target(file_ref, target, basename)
      end
      
      puts "    ✓ #{basename} → #{target_names.join(', ')}"
    end
  end
  
  # Remove old references for a group
  def cleanup_group(group_config)
    group_name = group_config[:name]
    target_names = group_config[:targets]
    
    puts "Cleaning up group: #{group_name}"
    
    # Find existing group
    group = @main_group.groups.find { |g| g.display_name == group_name }
    
    if group
      # Get file references before clearing
      file_refs = group.files.to_a
      
      # Remove from targets
      targets = target_names.map { |name| find_target(name) }.compact
      targets.each do |target|
        resources_phase = target.resources_build_phase
        
        file_refs.each do |file_ref|
          build_file = resources_phase.files.find { |bf| bf.file_ref == file_ref }
          resources_phase.files.delete(build_file) if build_file
        end
      end
      
      # Remove group
      group.remove_from_project
    end
  end
  
  def save
    puts "\nSaving project..."
    @project.save
    puts "✅ Project saved successfully"
  end
  
  private
  
  def find_or_create_group(name, path)
    # Look for existing group
    group = @main_group.groups.find { |g| g.display_name == name }
    
    if group
      puts "  Found existing group"
      return group
    end
    
    # Create new group
    puts "  Creating new group"
    group = @main_group.new_group(name, path, :group)
    group
  end
  
  def find_files(directory, patterns)
    files = []
    
    patterns.each do |pattern|
      Dir.glob(File.join(directory, pattern)).sort.each do |file|
        files << file if File.file?(file)
      end
    end
    
    files.uniq
  end
  
  def find_target(name)
    target = @project.targets.find { |t| t.name == name }
    
    unless target
      puts "  ⚠️  Target not found: #{name}"
    end
    
    target
  end
  
  def add_file_to_target(file_ref, target, basename)
    # Get or create resources build phase
    resources_phase = target.resources_build_phase
    
    unless resources_phase
      puts "    ⚠️  No resources phase for target: #{target.name}"
      return
    end
    
    # Check if file is already in build phase
    existing = resources_phase.files.find { |bf| bf.file_ref == file_ref }
    
    if existing
      puts "    ℹ️  #{basename} already in #{target.name}"
      return
    end
    
    # Add file to resources build phase
    resources_phase.add_file_reference(file_ref)
  end
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main
  puts "=" * 80
  puts "Xcode Group Manager"
  puts "=" * 80
  puts
  
  # Check if project exists
  unless File.exist?(PROJECT_PATH)
    puts "❌ Project not found: #{PROJECT_PATH}"
    exit 1
  end
  
  # Create backup
  backup_path = "#{PROJECT_PATH}/project.pbxproj.backup"
  FileUtils.cp("#{PROJECT_PATH}/project.pbxproj", backup_path)
  puts "📦 Backup created: #{backup_path}"
  puts
  
  begin
    # Initialize manager
    manager = XcodeGroupManager.new(PROJECT_PATH)
    
    # Process each group
    GROUPS.each do |group_config|
      puts
      manager.cleanup_group(group_config)
      manager.populate_group(group_config)
    end
    
    # Save project
    puts
    manager.save
    
    puts
    puts "=" * 80
    puts "✅ Complete!"
    puts "=" * 80
    
  rescue => e
    puts
    puts "❌ Error: #{e.message}"
    puts e.backtrace.join("\n")
    exit 1
  end
end

main if __FILE__ == $PROGRAM_NAME

