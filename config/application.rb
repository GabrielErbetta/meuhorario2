require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MeuHorario
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Brasilia"
    # config.eager_load_paths << Rails.root.join("extras")

    # SMTP configuration for suggestion emails
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: 'smtp.gmail.com',
      port: 587,
      domain: 'gmail.com',
      user_name: ENV['GMAIL_USERNAME'].to_s,
      password: ENV['GMAIL_PASSWORD'].to_s,
      authentication: 'plain',
      enable_starttls_auto: true
    }
  end
end
