class Ywall < Sinatra::Base
  set :root, File.dirname(__FILE__)
  enable :static
    get '/' do
      erb :index # mobile client page
    end
    get '/wall' do 
      erb :wall # projector page
    end
    get '/admin' do
      erb :admin # control panel
    end
end