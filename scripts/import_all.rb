# import_all.rb - Add files and folders to Xcode project
require 'xcodeproj'
require 'optparse'

# Parse command line arguments
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby import_all.rb [options] [files/folders...]"

  opts.on("-p", "--project PROJECT", "Xcode project file (default: crakt.xcodeproj)") do |p|
    options[:project] = p
  end

  opts.on("-t", "--target TARGET", "Target name (default: crakt)") do |t|
    options[:target] = t
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end.parse!

# Set defaults
project_path = options[:project] || "crakt.xcodeproj"
target_name = options[:target] || 'crakt'

# Get files/folders from command line arguments
items_to_import = ARGV

if items_to_import.empty?
  puts "Error: No files or folders specified. Use: ruby import_all.rb file1 folder1 file2..."
  puts "Run with --help for more options."
  exit 1
end

# Check if the project file exists
unless File.exist?(project_path)
  puts "Error: Project file not found at #{project_path}"
  exit 1
end

# Open the project
project = Xcodeproj::Project.open(project_path)

# Find the main app target
target = project.targets.find { |t| t.name == target_name }
unless target
  puts "Error: Target '#{target_name}' not found."
  exit 1
end

# Helper method to remove duplicate file references from build phases
def remove_duplicates(target)
  duplicates_removed = 0
  
  # Check Sources build phase
  if sources_phase = target.source_build_phase
    file_paths = {}
    files_to_remove = []
    
    sources_phase.files.each do |build_file|
      if build_file.file_ref
        path = build_file.file_ref.real_path.to_s
        if file_paths[path]
          files_to_remove << build_file
          duplicates_removed += 1
        else
          file_paths[path] = build_file
        end
      end
    end
    
    files_to_remove.each { |f| sources_phase.files.delete(f) }
  end
  
  # Check Resources build phase
  if resources_phase = target.resources_build_phase
    file_paths = {}
    files_to_remove = []
    
    resources_phase.files.each do |build_file|
      if build_file.file_ref
        path = build_file.file_ref.real_path.to_s
        if file_paths[path]
          files_to_remove << build_file
          duplicates_removed += 1
        else
          file_paths[path] = build_file
        end
      end
    end
    
    files_to_remove.each { |f| resources_phase.files.delete(f) }
  end
  
  if duplicates_removed > 0
    puts "🧹 Removed #{duplicates_removed} duplicate file reference(s)"
  end
  
  duplicates_removed
end

# Helper method to check if file is already in build phases
def file_already_in_target?(target, file_path)
  # Normalize the path
  normalized_path = File.expand_path(file_path)
  
  # Check Sources build phase
  if sources_phase = target.source_build_phase
    sources_phase.files.each do |build_file|
      if build_file.file_ref && File.expand_path(build_file.file_ref.real_path.to_s) == normalized_path
        return true
      end
    end
  end
  
  # Check Resources build phase
  if resources_phase = target.resources_build_phase
    resources_phase.files.each do |build_file|
      if build_file.file_ref && File.expand_path(build_file.file_ref.real_path.to_s) == normalized_path
        return true
      end
    end
  end
  
  false
end

# Define a method to add a folder recursively
def add_folder_recursively(project, target, folder_path, parent_group)
  puts "Adding folder: #{folder_path}"

  # Find or create the corresponding Xcode group for the folder
  group = parent_group.find_subpath(File.basename(folder_path), true)

  Dir.glob("#{folder_path}/*") do |item_path|
    next if File.basename(item_path).start_with?('.') || File.basename(item_path) == '.DS_Store'

    if File.directory?(item_path)
      # Recursively add subfolders
      add_folder_recursively(project, target, item_path, group)
    else
      # Check if file already exists in target
      if file_already_in_target?(target, item_path)
        puts "  ⏭️  Skipping (already in target): #{item_path}"
        next
      end
      
      # Add a reference to the file
      puts "  ✅ Adding file: #{item_path}"
      file_ref = group.new_reference(item_path)

      # Add the file to the target's build phase
      if item_path.end_with?('.swift')
        target.add_file_references([file_ref])
      elsif item_path.end_with?('.xcassets')
        target.add_resources([file_ref])
      end
    end
  end
end

# Process each item from command line
items_to_import.each do |item_path|
  unless File.exist?(item_path)
    puts "Warning: #{item_path} does not exist, skipping"
    next
  end

  if File.directory?(item_path)
    # Add folder recursively
    add_folder_recursively(project, target, item_path, project.main_group)
  else
    # Check if file already exists in target
    if file_already_in_target?(target, item_path)
      puts "⏭️  Skipping (already in target): #{item_path}"
      next
    end
    
    # Add individual file
    puts "✅ Adding file: #{item_path}"
    file_ref = project.main_group.new_file(item_path)

    # Add the file reference to the target's build phase
    if item_path.end_with?('.swift')
      target.add_file_references([file_ref])
    elsif item_path.end_with?('.xcassets')
      target.add_resources([file_ref])
    end
  end
end

# Clean up any duplicates that may have been introduced
puts "\n🔍 Checking for duplicates..."
remove_duplicates(target)

# Save the changes to the project file
project.save()

puts "\n✅ Successfully processed #{items_to_import.length} items in '#{target_name}' target."

