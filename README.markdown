#CouchDICOM#


##DICOM object loader to CouchDB using Ruby DICOM and CouchREST##

**Requeriments**

* Ruby 1.9
* ImageMagick
* Bundler
* Gems: couchrest, couchrest_model, dicom, rmagick

**Installation**

* Install Ruby 1.9 - We reccomend using [RVM](http://rvm.io/) or [rbenv](https://github.com/sstephenson/rbenv) + [ruby_build](https://github.com/sstephenson/ruby-build)
* Install CouchDB - If you're a Mac user we recommend you install it via [Homebrew](http://mxcl.github.com/homebrew/) with _brew install couchdb_
* Install Imagemagick - If you're a Mac user we recommend you install it via Homebrew with _brew install imagemagick_

* Install Bundler with 'gem install bundler'
* Clone this repository and navigate to it's directory
* Run 'bundle install' to have Bundler install the necessary gems

**Configuration**

* Modify the following variables as needed for use as default in case of not options defined in the command line:
* DIRS = The directory to be read
* JPGDIR = The directory where JPEGS should be stored
* DBURL = The Database URL. Use authentication if you set up users in your database 
* DB_BULK_SAVE_CACHE_LIMIT = Bulk save cache maximum number of documents
* dicom_attachment = Define if DICOM files should be attached inside the CouchDB document
* jpeg_attachment = Define if JPEG files should be attached inside the CouchDB document (eg. for serving as WADO)
* In the terminal type:
	* cd scriptFolderLocation
	* chmod +x couchdicom.rb

**Usage**

In your terminal:

_./couchdicom.rb [options]_

* -a, --attachments                Switch to upload DICOM pixeldata as attachments
* -j, -- jpg_attachments 		   Switch to upload WADO objects as jpg attachments
* -f FOLDER                        Define the directory to be read
* -t JPG_FOLDER                    Define the directory where temporary JPEGS should be stored
* -d DB_URL                        Define Database URL

This should create the database and load all documents read from your DICOM files

**Example**

_./couchdicom.rb -a -j -f dicomFolder -t temporaryJpgFolder -d dbURL_

_./couchdicom.rb -h_

**Notes**

* The DICOM files need to be uncompressed (for now)
* Tha variable _bind_addresss_ in the couchDB database must be equal to 0.0.0.0 if you want to access the DB remotely