require_relative 'his_interface'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'

class PYTSGateway < BaseHandler
  
  
  def get_patient_info params

      uri = URI('https://localhost:8001/pts/smartems/Generate/gettoken')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
      request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
      response = http.request(request)
      token = JSON.parse(response.body)["access_token"]
      
      patient_uri = URI('https://localhost:8001/pts/smartems/api/getPatientInfo?hn='+params[:hn])
      req = Net::HTTP::Get.new(patient_uri)
      req['Authorization'] = "Bearer #{token}"
  
      res = Net::HTTP.start(patient_uri.host, patient_uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) { |http| http.request(req) }
      content = res.body
      puts content
      object = JSON.parse(content)
      return object 
      
  end
end