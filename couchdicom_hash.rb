#!/usr/bin/env ruby

# Modules required:
require 'rubygems'
require 'find'
require 'couchrest'
require 'couchrest_model'
require 'dicom'
require 'rmagick'
require 'optparse'
require 'json/ext'
require 'rest-client'
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
  DIRS = ["/Users/simonmd/Desktop/DATASETS/BOUVIER"]
end

if options[:jpg_folder]
  JPGDIR = options[:jpg_folder]
else
  JPGDIR = "/Users/simonmd/Desktop/WADOS"
end

if options[:db_url]
  DBURL = options[:db_url]
else
  DBURL = "http://admin:admin@localhost:5984/couchdicom"
end
 
DB_BULK_SAVE_CACHE_LIMIT = 500 # Define Bulk save cache limit
dicom_attachment = false # Define if DICOM files should be attached inside the CouchDB document
jpeg_attachment = false # Define if JPEG files should be attached inside the CouchDB document (eg. for serving as WADO)

# Intialize logger
log = Logger.new('couchdicom_import.log')
log.level = Logger::WARN
log.debug("Created logger")
log.info("Program started")
DICOM.logger = log
DICOM.logger.level = Logger::DEBUG

# Set key_representation to remove spaces
DICOM.key_use_tags

# Create CouchDB database if it doesn't already exist
db_create_result = RestClient.put(DBURL, '')

# Set the limit of documents for bulk updating
# DB.bulk_save_cache_limit = DB_BULK_SAVE_CACHE_LIMIT

# Discover all the files contained in the specified directory and all its sub-directories:
excludes = ['DICOMDIR']
files = Array.new()
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

# Start total timer
total_start_time = Time.now

# Use a loop to run through all the files, reading its data and transferring it to the database.
files.each_index do |i|
  iteration_start_time = Time.now
  # Read the file:
  log.info("Attempting to read file #{files[i]} ...")
  dcm = DObject.read(files[i])
  # If the file was read successfully as a DICOM file, go ahead and extract content:
  if dcm.read_success
    log.info("Successfully read file #{files[i]}")

    # Convert DICOM tag structure to JSON:
    dcmhash = dcm.to_hash

    # Save filepath in hash
    # h["_filepath"] = files[i]

    # Read in the dicom file as a 'file' object
    file = File.new(files[i])

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
    # log.info("Attempting to load pixel data for file #{files[i]} ...")
    # if dcm.image
    #   log.info("Pixel data for file #{files[i]} read successfully")
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
    #   log.warn("could not read pixel data for file #{files[i]} ...")
    # end
  end

    # Save the CouchDB document
    begin
      document_create_result = RestClient.post DBURL, dcmjson, :content_type => :json, :accept => :json
      # Uncomment if bulk saving is desired (Little performance gain, bottleneck is in dicom reads)
      # currentdicom.save(bulk  = true)
      # If an error ocurrs, raise exception and log it
    rescue Exception => exc
      log.warn("Could not save file #{files[i]} to database; Error: #{exc.message}")
    end

  end

  # Log processing time for the file
  iteration_end_time = Time.now
  iterationtime = iteration_end_time - iteration_start_time
  log.info("Iteration time for file #{i} finished in #{iterationtime} s")
end

# Log total processing time
total_end_time = Time.now
totaltime = total_end_time - total_start_time
log.info("Full processing time: #{totaltime} seconds")
# Close the logger
log.close
