# Mediaclue, webbasierte Mediendatenbank
# Copyright (C) 2009 Andreas Brodbeck, mindclue GmbH
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA



# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# ATTENTION: UGLY HACK
# Some preloading plugins force to load model classes and try to connect to the database
# RUNNING_FROM_RAKE = defined?(Rake)
# Auf der Shell kann folgende Env-Variable gesetzt werden, damit man nicht in den Deadlock reinläuft, wonach has_many_polymorphs
# und anderes viel zu früh auf die DB zugreifft. Zum Beispiel:
# > rake db:migrate SUPRESS_EARLY_DB_CONNECTION=yes
SUPRESS_EARLY_DB_CONNECTION = ENV['SUPRESS_EARLY_DB_CONNECTION'] || false

# Hack für RubyInline. Dieses braucht ein "sicheres" Verzeichnis (zumindest bei mir lokal, wenn man es via Locomotive startet und deshalb kein HOME-Verzeichnis hat.)
rubyinline_dir = '/tmp/inlinedir'
Dir::mkdir(rubyinline_dir, 0700) unless File::directory?(rubyinline_dir)
ENV['INLINEDIR'] = rubyinline_dir

# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION
RAILS_GEM_VERSION = '2.1.2' unless defined? RAILS_GEM_VERSION
                         
###################################################################################################
# Applikations-Konstanten

LOCAL_DEVELOPMENT_ANDREAS = ENV['HOME'] && ENV['HOME'].include?('/Users/dassi')
LOCAL_DEVELOPMENT_WALID = ENV['HOME'] && ENV['HOME'].include?('/Users/walid')
LOCAL_DEVELOPMENT = LOCAL_DEVELOPMENT_ANDREAS || LOCAL_DEVELOPMENT_WALID


# Applikationsweite Konstanten laden
require File.join(File.dirname(__FILE__), 'constants')
                                                                     
# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# early gems
ACTS_AS_FERRET_VERSION = '=0.4.3'  # Version 0.4.4 ist kaputt, vermutlich
gem 'acts_as_ferret', ACTS_AS_FERRET_VERSION
require 'acts_as_ferret'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'ferret', :version => '>=0.11.6'
  config.gem 'acts_as_ferret', :version => ACTS_AS_FERRET_VERSION

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  config.plugins = [:all]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  # config.time_zone = 'UTC'


  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_mediaclue_session',
    :secret      => 'c21ab8779fe5af133a72d063d6a888b66fd57d555ed84af55de22289615e38f3b39fc1ed440e02d96def0a0b014d623328c00ac4e7078e60a7f1e6cae683e2f6'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  config.action_mailer.delivery_method = :sendmail
  
end

require 'tagging_extensions'

# gems nach rails initialize
require 'uuidtools'

# Hack, damit die Klasse Tag sicher geladen wird um das Klassen-lade-problem zu lösen. Siehe auch:
# http://rubyforge.org/forum/message.php?msg_id=26687
# http://rubyforge.org/forum/message.php?msg_id=27982
require_dependency 'tag' unless SUPRESS_EARLY_DB_CONNECTION


if FileTest.exist?('REVISION')
  REVISION = File.read('REVISION')
else
  REVISION = 'unknown revision'
end
                          
# DATABASE_NAME = ActiveRecord::Base.connection.current_database unless SUPRESS_EARLY_DB_CONNECTION
                                                                    
