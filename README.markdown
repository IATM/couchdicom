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

* Modify the following variables as needed:
* DIRS = The directory to be read
* JPGDIR = The directory where JPEGS should be stored
* DBURL = The Database URL. Use authentication if you set up users in your database 
* DB_BULK_SAVE_CACHE_LIMIT = Bulk save cache maximum number of documents

**Usage**

In your terminal:

_ruby couchdicom.rb_

This should create the database and load all documents read from your DICOM files

**Notes**

* The DICOM files need to be uncompressed (for now)
* Tha variable _bind_addresss_ in the couchDB database must be equal to 0.0.0.0 if you want to access the DB remotely