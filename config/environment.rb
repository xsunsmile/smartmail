# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require "smtp_tls"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "ruby-debug"

  config.gem(
    'mislav-will_paginate',
    :version => '~> 2.3.6',
    :lib => 'will_paginate',
    :source => 'http://gems.github.com')

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Tokyo'
  config.log_level = :error

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  RUOTE_ENV = {}
    # passing a hash of parameters (application context) to the ruote engine
    # (well via the ruote_plugin)

  $:.unshift('~/ruote/lib')
  # using the local 'ruote', comment that out if you're using ruote as a gem
  #
  config.action_mailer.smtp_settings = {
      :address => "smtp.gmail.com",
      :port => 587,
      :domain => "milog.jp",
      :authentication => :login,
      :user_name => "smart.mailflow@gmail.com",
      :password => "gks-smartmail"
  }
  # config.action_mailer.sendmail_settings = {
  #    :location => "localhost",
  #    :arguments => "-i -t"
  # }
  # config.action_mailer.delivery_method = :sendmail
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_charset = "iso-2022-jp"

end

class Logger
    def format_message(severity, timestamp, progname, msg)
        #"#{timestamp} (#{$$}) #{msg}\n"
        "#{timestamp.strftime('%Y/%m/%d %H:%M:%S')}.#{timestamp.usec.to_s[0, 3]} (#{$$}) #{msg}\n"
    end
end
