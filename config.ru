require 'dashing'
require 'omniauth/azure_activedirectory'

configure do
  set :auth_token, ENV['AUTH_TOKEN']

  helpers do
    def protected!
      # Put any authentication code you want in here.
      # This method is run before accessing any resource.
      default_auth = ENV['RACK_ENV'] == 'development' ? 'developer' : 'azureactivedirectory'
      redirect "/auth/#{default_auth}" unless session[:user_id]
    end
  end

  use Rack::Session::Cookie, secret: ENV.fetch('COOKIE_SECRET') { 'g7kmeV9hxAFkkIXY' }
  use OmniAuth::Strategies::Developer if ENV['RACK_ENV'] == 'development'
  use OmniAuth::Builder do
    provider :developer if ENV['RACK_ENV'] == 'development'
    provider :azure_activedirectory, ENV['AAD_CLIENT_ID'], ENV['AAD_TENANT']
  end

  post '/auth/:provider/callback' do
    if auth = request.env['omniauth.auth']
      session[:user_id] = auth['info']['email']
      redirect '/'
    else
      redirect '/auth/failure'
    end
  end

  get '/auth/failure' do
    'Nope.'
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
