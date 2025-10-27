require_relative 'his_interface'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'

class SVHGateway < BaseHandler
  

require 'nokogiri'
 

def  get_patient_samit content
  

  # content = File.open('getPatientData-result.xml').read
   #12-05-000
  # puts content

   require 'date'
  @doc = Nokogiri::XML(content)


    gender = '0'
    gender = '1' if @doc.xpath('//Gender').text =='0'
    gender = '2' if @doc.xpath('//Gender').text =='1'
    

                 
                 eng_name = @doc.xpath('//EngName').text.strip.split

                 obj =  {:status=>200, 
                 # :s_hn=>shn,
                 :name=>@doc.xpath('//PAPER_STNAMELINE1').text,
                 :prefix=>@doc.xpath('//PAPMI_NAME3').text,
       
                 :first_name=>@doc.xpath('//PAPMI_NAME').text, 
                 :last_name=>@doc.xpath('//PAPMI_NAME2').text, 
          
                 :gender=>gender, 
                 :birth_date=>Date.parse(@doc.xpath('//PAPMI_DOB').text).strftime("%d/%m/%Y"),
                 :public_id=>@doc.xpath('//IDCard').text,
                 :contact_country=>@doc.xpath('//CTNAT_Desc').text,
                 :born_country=>@doc.xpath('//CTNAT_CODE').text
         
          }
        
        return obj
  
  
end

  
  def get_patient_info params


      
      uri = URI("http://10.104.10.41/patientinfo/Patientinfo.asmx/getPatientData?hn=#{params[:hn]}")
      http = Net::HTTP.new(uri.host, uri.port)

      content = Net::HTTP.get(uri)

      puts content

      obj = get_patient_samit content
      obj[:hn] = params[:hn]
      obj['statuscode'] = 200
      puts obj.inspect

      #http.use_ssl = true
      #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
    #   request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
    #   response = http.request(request)
    #   token = JSON.parse(response.body)["access_token"]
      
    #   patient_uri = URI('https://localhost:8001/pts/smartems/api/getPatientInfo?hn='+params[:hn])
    #   req = Net::HTTP::Get.new(patient_uri)
    #   req['Authorization'] = "Bearer #{token}"
  
    #   res = Net::HTTP.start(patient_uri.host, patient_uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) { |http| http.request(req) }
    #   content = res.body
    #   puts content
    #   object = JSON.parse(content)


      return obj 
      
  end
end