require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Mongologue
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # config.autoload_paths += %W(#{config.root}/app/sweepers)


    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.assets.enabled = true
    # config.assets.prefix = "/assets"

    # Mongoid.configure do |config|
    #  config.logger = nil
    # end

    # config.mongoid.preload_models = false


    # config.cache_store = :dalli_store, 'localhost:11211', { compress: false }
    # ActionController::Base.cache_store = :mem_cache_store, "localhost"
    # config.cache_store = :redis_store
    config.cache_store = :mem_cache_store
    #config.cache_store = :memcached_store, '127.0.0.1:11211', { :no_block => true, :buffer_requests => true,
    #                                        :noreply => true, :binary_protocol => false }

     # add unicode support for strings everywhere
     String.class_eval  'def downcase
         Unicode::downcase(self)
       end
       def downcase!
         self.replace downcase
       end

       def upcase
         Unicode::upcase(self)
       end
       def upcase!
         self.replace upcase
       end
       def capitalize
         Unicode::capitalize(self)
       end

       def capitalize!
         self.replace capitalize
       end

       def strip_tags
         ActionController::Base.helpers.strip_tags(self)
       end'

  end
end
