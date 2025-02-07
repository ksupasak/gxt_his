
require 'json'
require 'mqtt'
require 'thread'


MQTT_BROKER = 'mqtts://mqtt.pcm-life.com:' # Change to your actual broker address

MQTT_USERNAME = 'mqttuser' # Change to your username
MQTT_PASSWORD = 'Minadadmin_2010' # Change to your password


MQTT_SSL_OPTS = {
  host: 'mqtt.pcm-life.com',
  port: 8883, # MQTT over TLS
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  cert_file: '../config/cert.pem',
  key_file:  '../config/key.pem',
  ssl: true
}


# Thread-safe response storage
responses = {}
mutex = Mutex.new

# MQTT Subscriber Thread (Secure)
Thread.new do
  MQTT::Client.connect(  MQTT_SSL_OPTS) do |client|
    client.subscribe('his/response_patient')

    client.get do |topic, message|
      puts "Received response: #{message}"
      data = JSON.parse(message) rescue {}

      if data["hn"]
        mutex.synchronize do
          responses[data["hn"]] = data
        end
      end
    end
  end
end



request_payload = { hn: 1234 }.to_json

MQTT::Client.connect(MQTT_SSL_OPTS) do |client|
  r = client.publish('snh/patient_request', request_payload)
  puts r
end

puts 'ok'