Mongologue::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests

  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # cachiing
  ####################################################################
  # config.cache_store = :mem_cache_store

  CACHE = Memcached.new("localhost:11211",{ :no_block => true, :buffer_requests => true,
                                            :noreply => true, :binary_protocol => false })

  # connect to your server that you started earlier

  # this is where you deal with passenger's forking
  begin
     PhusionPassenger.on_event(:starting_worker_process) do |forked|
       if forked
         # We're in smart spawning mode, so...
         # Close duplicated memcached connections - they will open themselves
         CACHE.reset
       end
     end
  # In case you're not running under Passenger (i.e. devmode with mongrel)
  rescue NameError => error
  end

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Specify the default JavaScript compressor
  config.assets.js_compressor  = :uglifier

  # Specifies the header that your server uses for sending files
  # (comment out if your front-end server doesn't support this)
  config.action_dispatch.x_sendfile_header = "X-Sendfile" # Use 'X-Accel-Redirect' for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :error

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.raise_delivery_errors = true
  ActionMailer::Base.sendmail_settings = {
  :location       => '/usr/sbin/sendmail',
  :arguments      => '-i'
  }


  # Enable threaded mode
  config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
