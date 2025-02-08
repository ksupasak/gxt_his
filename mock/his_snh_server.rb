require 'net/http'
require 'json'
require 'mqtt'
require 'thread'


MQTT_BROKER = 'mqtts://mqtt.pcm-life.com:' # Change to your actual broker address

MQTT_USERNAME = ENV['MQTT_USERNAME'] || 'mqttuser' # Change to your username
MQTT_PASSWORD =  ENV['MQTT_PASSWORD'] || '-' # Change to your password
TOKEN = ENV['TOKEN'] || '123457' 

MQTT_SSL_OPTS = {
  host: 'mqtt.pcm-life.com',
  port: 8883, # MQTT over TLS
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  cert_file: '../config/cert/cert.pem',
  key_file:  '../config/cert/key.pem',
  ssl: true
}

puts MQTT_SSL_OPTS.inspect

# Thread-safe response storage
responses = {}
mutex = Mutex.new


def send_patient url, hn 
  
  
  url = URI.parse(url)
  
  payload = {
    "statuscode": 200,
    "statusmessage": "Get Patient Success!",
    "data": {
        "hn": hn || "63-01331",
        "cid": nil,
        "prefix_name": "Mr.",
        "fname": "SAW LA",
        "lname": "KWAL",
        "prefix_en": "Mr.",
        "fname_en": nil,
        "lname_en": nil,
        "gender": "ชาย",
        "brithdate": "1991-07-20",
        "patient_phone": nil,
        "contact_phone": "094-8923596",
        "address": "บ.ศรีราชาโชคสำราญ จำกัดเลขที่ 377/85-87",
        "nationality": "พม่า"
    }
    }.to_json
  
  
  # Create HTTP request
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true  # Enable SSL
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  puts "TOKEN #{TOKEN}"  

  request = Net::HTTP::Post.new(url, { 'Content-Type' => 'application/json' ,"Authorization" => TOKEN})
  request.body = payload

  # Send the request
  response = http.request(request)

  # Print response
  puts "Response Code: #{response.code}"
  puts "Response Body: #{response.body}"
  
end



# MQTT Subscriber Thread (Secure)
Thread.new do
  MQTT::Client.connect(  MQTT_SSL_OPTS) do |client|
    client.subscribe('snh/patient_request')

    client.get do |topic, message|
      puts "Received response: #{message}"
      data = JSON.parse(message) rescue {}

      if data["hn"]
        mutex.synchronize do
          
          # responses[data["hn"]] = data
          if data['url']
            send_patient data['url'], data['hn']
          end
          
        end
      end
    end
  end
end

# Wait for response (timeout after 5 seconds)
timeout = Time.now + 100
while true
  mutex.synchronize do
  
    puts '.'
    # if responses.key?(hn)
  #     return responses.delete(hn).to_json
  #   end
  end
  sleep 1
end


#
# request_payload = { hn: 1234 }.to_json
#
# MQTT::Client.connect(MQTT_SSL_OPTS) do |client|
#   r = client.publish('snh/patient_request', request_payload)
#   puts r
# end

puts 'ok'