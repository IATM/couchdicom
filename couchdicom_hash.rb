#!/usr/bin/env ruby

# Modules required:
require 'rubygems'
require 'find'
require 'dicom'
require 'rmagick'
require 'optparse'
require 'json/ext'
require 'rest-client'
require 'parallel'
require 'ruby-progressbar'
include DICOM

options = {}
option_parser = OptionParser.new do |opts|
  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Load the DICOM metadata contained in a folder in a COUCHDB database
  Usage: ./#{executable_name} [options]
  "
  opts.on("-a","--attachments", "Switch to upload DICOM pixeldata as attachments") do 
    options[:attachments] = true
  end
  
  opts.on("-j","--jpg_attachments", "Switch to upload WADO objects as attachments") do 
    options[:jpg_attachments] = true
  end

  opts.on("-f FOLDER", "Define the directory to be read") do |folder| 
    options[:folder] = folder
  end
  
  opts.on("-t JPG_FOLDER", "Define the directory where temporary JPEGS should be stored") do |jpg_folder| 
    options[:jpg_folder] = jpg_folder
  end
  
  opts.on("-d DB_URL", "Define Database URL") do |db_url| 
    options[:db_url] = db_url
  end 
end
option_parser.parse!

# Constants
if options[:folder]
  DIRS = [options[:folder]]
else
  DIRS = ["/Users/simonmd/Desktop/mrptests/smallbatch"]
end

if options[:jpg_folder]
  JPGDIR = options[:jpg_folder]
else
  JPGDIR = "/Users/simonmd/Desktop/WADOS"
end

if options[:db_url]
  DBURL = options[:db_url]
else
  DBURL = "http://localhost:5984/mrparametrix"
end
 
dicom_attachment = false # Define if DICOM files should be attached inside the CouchDB document
jpeg_attachment = false # Define if JPEG files should be attached inside the CouchDB document (eg. for serving as WADO)

# Intialize logger
log = Logger.new('couchdicom_import.log')
log.level = Logger::WARN
log.debug("Created logger")
log.info("Program started")
DICOM.logger = log
DICOM.logger.level = Logger::WARN

# Set key_representation to remove spaces
DICOM.key_use_tags

# Start message
puts "CouchDICOM is starting..."

# Create CouchDB database if it doesn't already exist
# db_create_result = RestClient.put(DBURL, '')

# Discover all the files contained in the specified directory and all its sub-directories:
excludes = ['DICOMDIR']
files = Array.new()
# Begin recursive directory search message
puts "Looking for files in #{DIRS}"
for dir in DIRS
  Find.find(dir) do |path|
    if FileTest.directory?(path)
      if excludes.include?(File.basename(path))
        Find.prune  # Don't look any further into this directory.
      else
        next
      end
    else
      files += [path]  # Store the file in our array
    end
  end
end
# Report how many files were found
puts "Finished searching recursively through #{DIRS}, found #{files.size} files."

# Start total timer
total_start_time = Time.now
# Start message
puts "Beginning CouchDICOM import for #{files.size} files..."
# Initialize progress bar
progress = ProgressBar.create(:title => "CouchDICOM import progress", :total => files.size)
# Use a Parallel to run through all the files, reading its data and transferring it to the database.
Parallel.map(files, :finish => lambda { |item, i| progress.increment }) do |dfile|
  iteration_start_time = Time.now
  # Read the file:
  log.info("Attempting to read file #{dfile} ...")
  dcm = DObject.read(dfile)
  # If the file was read successfully as a DICOM file, go ahead and extract content:
  if dcm.read_success
    log.info("Successfully read file #{dfile}")

    # Convert DICOM tag structure to JSON:
    dcmhash = dcm.to_hash

    # Save filepath in hash
    # h["_filepath"] = dfile

    # Read in the dicom file as a 'file' object
    file = File.new(dfile)

    # Set document id to SOP Instance UID (Should be unique)
    dcmhash["_id"] = dcmhash["0008,0018"]

    #Convert DICOM hash to URI-encoded JSON
    dcmjson = dcmhash.to_json

  # Check if DICOM attachment is selected
  if options[:attachments] == true
    # Create the attachment from the actual dicom file
    # currentdicom.create_attachment({:name => 'imagedata', :file => file, :content_type => 'application/dicom'})
  end

  # Check if JPEG attachment is selected
  if options[:jpg_attachments] == true
    # # Load pixel data to ImageMagick class
    # log.info("Attempting to load pixel data for file #{dfile} ...")
    # if dcm.image
    #   log.info("Pixel data for file #{dfile} read successfully")
    #   image = dcm.image.normalize
    #   # Save pixeldata as jpeg image in wado cache directory
    #   wadoimg_path = "#{JPGDIR}/wado-#{currentdicom.docuid}.jpg"
    #   # Write the jpeg for WADO
    #   image.write(wadoimg_path)
    #   # Read to insert in attachment (SURELY this can be done directly)
    #   wadofile = File.new(wadoimg_path)
    #   # Create an attachment from the created jpeg
    #   currentdicom.create_attachment({:name => 'wadojpg', :file => wadofile, :content_type => 'image/jpeg'})
    # else
    #   log.warn("could not read pixel data for file #{dfile} ...")
    # end
  end

    # Save the CouchDB document
    begin
      document_create_result = RestClient.post DBURL, dcmjson, :content_type => :json, :accept => :json
      # If an error ocurrs, raise exception and log it
    rescue Exception => exc
      log.warn("Could not save file #{dfile} to database; Error: #{exc.message}")
    end

  end

  # Log processing time for the file
  iteration_end_time = Time.now
  iterationtime = iteration_end_time - iteration_start_time
  log.info("Iteration time for file #{dfile} finished in #{iterationtime} s")
end

# Log total processing time
total_end_time = Time.now
totaltime = total_end_time - total_start_time
log.info("Full processing time: #{totaltime} seconds")

# Finished message
puts "CouchDICOM finished importing #{files.size} files in #{totaltime} seconds, have a nice day!"
# Close the logger
log.close
