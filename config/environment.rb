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
# Auf der Shell kann folgende Env-Variable gesetzt werden, damit man nicht in den Deadlock reinläuft, wonach has_many_polymorphs
# und anderes viel zu früh auf die DB zugreifft. Zum Beispiel:
# > rake db:migrate SUPRESS_EARLY_DB_CONNECTION=yes
SUPRESS_EARLY_DB_CONNECTION = ENV['SUPRESS_EARLY_DB_CONNECTION'] || false

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION
                         
###################################################################################################
# Applikations-Konstanten

LOCAL_DEVELOPMENT_ANDREAS = ENV['HOME'] && ENV['HOME'].include?('/Users/dassi')
LOCAL_DEVELOPMENT_WALID = ENV['HOME'] && ENV['HOME'].include?('/Users/walid')
LOCAL_DEVELOPMENT = LOCAL_DEVELOPMENT_ANDREAS || LOCAL_DEVELOPMENT_WALID


# Applikationsweite Konstanten laden
require File.join(File.dirname(__FILE__), 'constants')

# Pfad allenfalls anpassen
if ADDITIONAL_ENV_PATHS.any?
  ENV['PATH']="#{ADDITIONAL_ENV_PATHS.join(':')}:#{ENV['PATH']}"
end
                                                                     
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
  config.gem 'ferret', :version => '~>0.11.6'
  config.gem 'acts_as_ferret', :version => ACTS_AS_FERRET_VERSION
  config.gem 'mime-types', :version => '~>1.19', :lib => 'mime/types'
  config.gem 'mini_exiftool', :version => '~>1.0.1'
  config.gem 'rubyzip', :lib => 'zip/zip', :version => '~>0.9.1'
  config.gem 'ruport', :version => '~>1.6.1'
  config.gem 'bj', :version => '~>1.0.1'
  config.gem 'main', :version => '~>2.8.0' # BJ braucht main 2.8.0!!! Die neueren führen zu Exception!
  config.gem 'daemon_controller', :lib => 'daemon_controller', :version => '~>0.2.1'
  config.gem 'image_science', :version => '~>1.2.1'
  config.gem 'haml', :version => '~>2.2.5'
  
  if FEATURE_LDAP_AUTHENTICATION
    config.gem 'ruby-ldap', :version => '=0.9.9', :lib => false
    config.gem 'activeldap', :version => '~>1.2.2', :lib => 'active_ldap'
  end    

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

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # config.action_mailer.delivery_method = :sendmail
  config.action_mailer.default_url_options = { :host => APPLICATION_DOMAIN }
  
  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = :de_ch

  config.action_controller.use_accept_header = false
  
end

require 'ruby_extensions'
require 'tagging_extensions'
require 'rails_extensions'
require 'ruport_extensions'

# Aufgrund von Problemen auf einer Debian-Maschine, wurde dies hier gefunden:
require 'image_science'

autoload(:PreviewGenerator, 'support/preview_generator.rb')

# gems nach rails initialize
gem 'uuidtools', '~>1.0.3'
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

# Haml soll nur doppelte Anführungszeichen in HTML verwenden.                                                                    
Haml::Template.options[:attr_wrapper] = '"'

# Konfig-Konstanten für LDAP implizit erzeugen, aus der Konfiguration des ActiveLdap gems in ldap.yml
if FEATURE_LDAP_AUTHENTICATION
  require 'support/ldap_models.rb'
  LDAP_HOST = ActiveLdap::Base.configuration('host')
  LDAP_BASE_DN = ActiveLdap::Base.configuration('base')
end