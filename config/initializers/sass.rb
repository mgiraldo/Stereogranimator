Sass::Plugin.options.merge!(
  :template_location => 'assets/stylesheets',
  :css_location => 'tmp/stylesheets'
)

Rails.configuration.middleware.delete('Sass::Plugin::Rack')
Rails.configuration.middleware.insert_before('Rack::Sendfile', 'Sass::Plugin::Rack')

Rails.configuration.middleware.insert_before('Rack::Sendfile', 'Rack::Static',
    :urls => ['/assets/stylesheets'],
    :root => "#{Rails.root}/tmp")