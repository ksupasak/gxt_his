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

# Trusted Proxy IP Ranges
TRUSTED_PROXIES = [
  IPAddr.new("127.0.0.1/32"),
  IPAddr.new("10.0.0.0/8"),
  IPAddr.new("172.16.0.0/12")
]

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


# Trusted proxy check
def trusted_proxy?(ip)
  addr = IPAddr.new(ip) rescue nil
  addr && TRUSTED_PROXIES.any? { |r| r.include?(addr) }
end

# Resolve trusted_proxy config to IP ranges
def resolve_trusted_proxy_ranges(trusted_proxy_config)
  return [] unless trusted_proxy_config
  
  ranges = []
  trusted_proxy_config.each do |proxy|
    case proxy
    when "nginx"
      # Docker network ranges (common defaults)
      ranges << IPAddr.new("172.16.0.0/12")  # Docker default bridge network
      ranges << IPAddr.new("172.18.0.0/16")  # Docker compose default network
      ranges << IPAddr.new("10.0.0.0/8")     # Docker custom networks
    else
      # Assume it's a subnet string like "172.18.0.0/16"
      begin
        ranges << IPAddr.new(proxy)
      rescue IPAddr::InvalidAddressError
        puts "Warning: Invalid trusted_proxy subnet: #{proxy}"
      end
    end
  end
  ranges
end

# Get real client IP from request
def get_real_client_ip(auth_config = nil)
  # Check if we're behind a trusted proxy
  proxy_ip = request.ip
  puts "DEBUG: proxy_ip (request.ip) = #{proxy_ip}"
  puts "DEBUG: X-Forwarded-For = #{request.env['HTTP_X_FORWARDED_FOR']}"
  puts "DEBUG: X-Real-IP = #{request.env['HTTP_X_REAL_IP']}"
  
  # Check if proxy is trusted (from auth config)
  if auth_config && auth_config['trusted_proxy']
    trusted_ranges = resolve_trusted_proxy_ranges(auth_config['trusted_proxy'])
    puts "DEBUG: trusted_proxy config = #{auth_config['trusted_proxy']}"
    puts "DEBUG: resolved trusted_ranges = #{trusted_ranges.map(&:to_s)}"
    
    is_trusted = trusted_ranges.any? { |r| 
      begin
        proxy_addr = IPAddr.new(proxy_ip)
        result = r.include?(proxy_addr)
        puts "DEBUG: Checking if #{proxy_ip} in #{r.to_s}: #{result}"
        result
      rescue => e
        puts "DEBUG: Error checking proxy IP: #{e.message}"
        false
      end
    }
    
    puts "DEBUG: is_trusted (from auth config) = #{is_trusted}"
    
    if is_trusted
      # Get real IP from X-Forwarded-For or X-Real-IP header
      forwarded_for = request.env['HTTP_X_FORWARDED_FOR']
      real_ip_header = request.env['HTTP_X_REAL_IP']
      
      if forwarded_for && !forwarded_for.strip.empty?
        # X-Forwarded-For can contain multiple IPs, take the first one
        real_ip = forwarded_for.split(',').first.strip
        puts "Trusted proxy detected: #{proxy_ip}, Real client IP (from X-Forwarded-For): #{real_ip}"
        return real_ip
      elsif real_ip_header && !real_ip_header.strip.empty?
        # Fallback to X-Real-IP if X-Forwarded-For is not present
        puts "Trusted proxy detected: #{proxy_ip}, Real client IP (from X-Real-IP): #{real_ip_header}"
        return real_ip_header
      else
        puts "WARNING: Trusted proxy detected but no X-Forwarded-For or X-Real-IP header found"
      end
    end
  end
  
  # Also check against global TRUSTED_PROXIES
  if trusted_proxy?(proxy_ip)
    forwarded_for = request.env['HTTP_X_FORWARDED_FOR']
    real_ip_header = request.env['HTTP_X_REAL_IP']
    
    if forwarded_for && !forwarded_for.strip.empty?
      real_ip = forwarded_for.split(',').first.strip
      puts "Trusted proxy detected (global): #{proxy_ip}, Real client IP (from X-Forwarded-For): #{real_ip}"
      return real_ip
    elsif real_ip_header && !real_ip_header.strip.empty?
      puts "Trusted proxy detected (global): #{proxy_ip}, Real client IP (from X-Real-IP): #{real_ip_header}"
      return real_ip_header
    end
  end
  
  # Default to direct connection IP
  puts "DEBUG: Using direct connection IP: #{proxy_ip}"
  proxy_ip
end

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
  
    # Get real client IP (handles trusted proxies)
    real_client_ip_str = get_real_client_ip(auth)
    puts "DEBUG: real_client_ip_str = #{real_client_ip_str}"
    begin
      client_ip = IPAddr.new(real_client_ip_str)
    rescue => e
      puts "ERROR: Invalid IP address: #{real_client_ip_str} - #{e.message}"
      halt 403, { error: 'Access forbidden - Invalid IP' }.to_json
    end
    
    # Build allowed IP list
    list = white_list + auth['ip'].collect{|i| 
      begin
        IPAddr.new(i)
      rescue => e
        puts "WARNING: Invalid IP in whitelist: #{i} - #{e.message}"
        nil
      end
    }.compact
    
    puts "DEBUG: Checking IP #{real_client_ip_str} against whitelist:"
    list.each do |ip_range|
      result = ip_range.include?(client_ip)
      puts "DEBUG:   #{ip_range.to_s} includes #{real_client_ip_str}: #{result}"
    end
    
    unless list.any? { |ip_range| ip_range.include?(client_ip) }
      puts "Access denied for IP: #{real_client_ip_str}"
      halt 403, { error: 'Access forbidden' }.to_json
    end
    
    puts "Access granted for IP: #{real_client_ip_str}"
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