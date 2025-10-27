require 'sinatra'
require 'json'
require 'openssl'
require 'puma'
require 'yaml'

require_relative "his/his_factory"
# Example usage:
condition = ARGV[0] || "MOCK"  # Get condition from command-line argument or default to "A"

puts "AUTH = #{ENV['AUTH']}"
puts "CONFIG = #{ENV['CONFIG']}"

auth_path = ENV['AUTH'] || 'config/auth.yml'

auth = YAML.load_file(auth_path)

auth_map = {}

for i in auth['list']  
  auth_map[i['bearer']] = i
end


config_path = ENV['CONFIG'] || 'config/config.yml'

config = YAML.load_file(config_path)

# Allowed IP Ranges
white_list = [
  IPAddr.new('127.0.0.1'),          # Localhost
  IPAddr.new('192.168.1.0/24'),     # Allow all 192.168.1.x
  IPAddr.new('10.0.0.0/8')          # Allow all 10.x.x.x
  
]
puts white_list

set :port, 3000
set :bind, '0.0.0.0'
set :server, 'puma'
set :ssl, true

# SSL configuration
ssl_options = {
  cert: File.expand_path('config/server.crt', __dir__),
  key:  File.expand_path('config/server.key', __dir__)
}


# Run Puma with SSL
configure do
  set :ssl, true
  set :config, config
end


#@config = settings.config


# Authentication helper method
def authenticate! auth_map
  provided_token = request.env['HTTP_AUTHORIZATION']&.split('Bearer ')&.last
  halt 401, { error: 'Unauthorized' }.to_json unless auth_map[provided_token]
  return auth_map[provided_token]
end


before do
  
    if settings.ssl && request.scheme != 'https'
       redirect "https://#{request.host}:#{settings.port}#{request.fullpath}"
    end
    
    auth = authenticate!(auth_map)
    
    puts "Found token for #{auth['name']}"
  
    client_ip = IPAddr.new(request.ip)
    
    list = white_list + auth['ip'].collect{|i| IPAddr.new(i)}
    
    unless list.any? { |ip_range| ip_range.include?(client_ip) }
      halt 403, { error: 'Access forbidden' }.to_json
    end
    
    params[:config] = config
    
end


get '/' do
  send_file File.join(settings.public_folder, 'map.html')
end



# GET /his/getPatientInfo with Bearer Authentication
get '/his/getPatientInfo' do
  puts 'ok'

  condition = params[:his]
  
  handler = HISFactory.get_handler(condition)
  result = handler.get_patient_info params

  puts "xxxxxxxxx"
  puts result.inspect 
  puts "xxxxxxxxx"
  if result['statuscode']==200 #&& result[:status]==200
      return result.to_json 
  else
      return params.to_json 
  end

end


# POST /his/getPatientInfo with Bearer Authentication
post '/his/sendPatientInfo' do

  content_type :json
  request_body = request.body.read
  condition = params[:his]
  
  puts "POST data #{params.inspect}"
  puts request_body
  
  begin
    data = JSON.parse(request_body)
  rescue JSON::ParserError
    return { error: 'Invalid JSON' }.to _json
  end
  
  handler = HISFactory.get_handler(condition)
  result = handler.send_patient_info params, data
   
  return result

end