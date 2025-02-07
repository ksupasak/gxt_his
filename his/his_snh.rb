require_relative 'his_interface'
require 'mqtt'
require 'thread'
require 'redis'

class SNHGateway < BaseHandler
  
  
  def get_patient_info params

    # puts params[:config]
    
    mqtt_opt = params[:config]['mqtt']
    server = params[:config]['server']
    
    
    mutex = Mutex.new
    responses = {}
    
    puts "SNH Gateway executed!"

    request_payload = { hn: params[:hn], url: "https://#{server['host']}:#{server['port']}/his/sendPatientInfo?his=SNH&hn=#{params[:hn]}" }.to_json
    
    hn = params[:hn]
    
    thread = Thread.new do
    
    MQTT::Client.connect(mqtt_opt) do |client|
      
       #
      # MQTT Subscriber Thread (Secure)
  
      
      r = client.publish('snh/patient_request', request_payload)
      
      client.subscribe('snh/patient_response')

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
    
    
    # Wait for response (timeout after 5 seconds)
      timeout = Time.now + 5
      while Time.now < timeout
        puts '.'
        mutex.synchronize do
          if responses.key?(hn)
          Thread.kill(thread)
            # Connect to Redis
            redis = Redis.new(host:params[:config]['redis']['host'], port:params[:config]['redis']['port'], password:params[:config]['redis']['password'])
    
            data = redis.get("snh|#{params[:hn]}")
       
            data = JSON.parse(data)      
            redis.close
     
            return data
            
            
          end
        end
        sleep 0.5
      end
      
      
      Thread.kill(thread)

    return "Timeout"
  end
  
  
  def send_patient_info params, data

    request_payload = { hn: params[:hn] }.to_json
    puts params[:config]['redis']
    # Connect to Redis
    redis = Redis.new(host:params[:config]['redis']['host'], port:params[:config]['redis']['port'], password:params[:config]['redis']['password'])
    
    redis.set("snh|#{params[:hn]}", data.to_json)
    
    MQTT::Client.connect(params[:config]['mqtt']) do |client|
    r = client.publish('snh/patient_response', request_payload)
    end
    
    
    
    
  end
  
  
end