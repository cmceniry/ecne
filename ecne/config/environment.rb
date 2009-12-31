# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below
require 'syslog'
Syslog.close() if Syslog.opened?
Syslog.open("ecne", Syslog::LOG_PID|Syslog::LOG_CONS, Syslog::LOG_DAEMON)

module Ecne

  D_GROUPFILE = "/etc/ecne.groups"
  D_APGCMD    = "/usr/bin/apg"
  D_DISPLAYTIMEOUT = 60
  D_SESSIONTIMEOUT = 600

  begin
    @@config[:groupfile] = D_GROUPFILE if not @@config.key?(:groupfile)
    @@config[:apgcmd]    = D_APGCMD    if not @@config.key?(:apgcmd)
    @@config[:displaytimeout] = D_DISPLAYTIMEOUT if not @@config.key?(:displaytimeout)
    @@config[:sessiontimeout] = D_SESSIONTIMEOUT if not @@config.key?(:sessiontimeout)
  rescue NameError => e
    @@config = {
      :groupfile => D_GROUPFILE,
      :apgcmd    => D_APGCMD,
      :displaytimeout => D_DISPLAYTIMEOUT,
      :sessiontimeout => D_SESSIONTIMEOUT,
    }
  end

  @@groups = nil
  @@lastup = 0

  def Ecne::groupfile
    @@config[:groupfile]
  end

  def Ecne::apgcmd
    @@config[:apgcmd]
  end

  def Ecne::displaytimeout
    @@config[:displaytimeout]
  end

  def Ecne::sessiontimeout
    @@config[:sessiontimeout]
  end
  
  def Ecne::groups
    begin
      if @@groups.nil? or @@lastup < File.stat(groupfile).mtime
        @@lastup = File.stat(groupfile).mtime
        newgroups = {}
        YAML.load_file(groupfile).each_pair do |group, members|
          members.each do |user|
            newgroups[user] ||= []
            newgroups[user] << group unless newgroups[user].include?(group)
          end
        end
        @@groups = newgroups
      end
      @@groups
    rescue StandardError => e
      Syslog.log( Syslog::LOG_WARNING,
                  "Cant open groups file(%s): %s", 
                  groupfile,
                  e )
      @@groups || {}
    end
  end
  
  def Ecne::apg(options = {})
    begin
      modeopts = []
      modeopts << "L" if options[:lc]
      modeopts << "C" if options[:uc]
      modeopts << "N" if options[:n]
      modeopts << "S" if options[:s]
      mode = modeopts.join
      
      cmdopts = []
      cmdopts << "-m #{options[:min].to_i || 8}" 
      cmdopts << "-x #{options[:max].to_i || 8}"
      cmdopts << "-n #{options[:num].to_i || 5}"
      cmdopts << "-M #{modeopts}" if not modeopts.empty?      
      
      cmd = %{#{apgcmd} #{cmdopts.join(' ')} }
      res = %x{#{cmd}} 
      if $?.success?
        res
      else
        Syslog.log(Syslog::LOG_WARNING, "apg returned unsuccessfully(%d): %s", $?.exitstatus, res)
        "Cannot generate"
      end
    rescue StandardError => e
      Syslog.log(Syslog::LOG_WARNING, "generate threw an error: %s", e)
      "Cannot generate"
    end
  end
  
end
