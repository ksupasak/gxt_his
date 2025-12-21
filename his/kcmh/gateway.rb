require_relative '../his_interface'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'savon'


class KCMHGateway < BaseHandler
  

 
  
  def get_patient_info params


      
      # uri = URI("http://10.104.10.41/patientinfo/Patientinfo.asmx/getPatientData?hn=#{params[:hn]}")
      # http = Net::HTTP.new(uri.host, uri.port)


      if params[:hn]
        client = Savon.client do
           wsdl "his/kcmh/emr.wsdl"
        end

  puts client.operations
        hn = params[:hn]


 if params[:hn]

#puts params[:hn]

     if params[:hn].index('/')

     t = params[:hn].split('/')

     hn = "#{t[1]}#{format('%06d',t[0].to_i)}".to_i

     else

     #hn = params[:hn].to_i 

hn="#{params[:hn][-2..-1].to_i}#{format('%06d',params[:hn][0..-3].to_i)}".to_i

     end

   end

      thn= hn.to_s

puts hn


        response = client.call(:ws_emr_get_patient, message: { 'hn'=> hn ,'user'=> 'emr','Password'=>'1234','IPAddress'=>'170.100.50.10' }) 



 begin

        hash = response.to_hash
        puts hash.keys.inspect

        puts hash.inspect 

        hash = hash[:ws_emr_get_patient_response]
        puts hash.keys.inspect

        hash = hash[:ws_emr_get_patient_result]
        puts hash.keys.inspect

        hash = hash[:diffgram]
        puts hash.keys.inspect

        hash = hash[:new_data_set]
        puts hash.keys.inspect

        hash = hash[:datatbl]
        hash = hash


        hash = [hash] if hash.class.to_s=='Hash'

        o = nil
        for i in hash

        #puts "#{i} = #{hash[i]}" 
        # puts 
          for j in i.keys.sort
        #	puts "-#{j} = #{i[j]}"
          end

          if o == nil or  i[:p_out_idcard].size > o[:p_out_idcard].size 
            o = i
          end

        end

#puts o.inspect 

        if o 


          r = o 
          gender = 'M' if r[:p_out_sex]=='M'
          gender = 'F' if r[:p_out_sex]=='F'
          shn = thn[2..-1].to_i.to_s+"/"+thn[0..1]
          title = ""
          title = r[:p_out_patient_name][0..r[:p_out_patient_name].index(r[:p_out_fname])-1] if r[:p_out_patient_name].index(r[:p_out_fname])


          obj =  {:status=>200, 
            :s_hn=>shn,
            :name=>r[:p_out_patient_name],
            :prefix=>r[:p_out_pname],
            :title=>title,
            :first_name=>r[:p_out_fname], 
            :last_name=>r[:p_out_lname], 
            :name_eng=>r[:p_out_en_patient_name],
            :prefix_eng=>r[:p_out_en_pname],
            :first_name_eng=>r[:p_out_en_fname], 
            :last_name_eng=>r[:p_out_en_lname],
            :gender=>gender, 
            :birth_date=>Date.parse(r[:p_out_patient_dob].to_s).strftime("%d/%m/%Y"),
            :public_id=>r[:p_out_idcard],
            :contact_country=>'ประเทศไทย',
            :born_country=>'ประเทศไทย',
            # :tel_home=>data[:present_tel], 
            :mobile=>r[:p_out_present_mobile], 
            # :email=>data[:present_email],
          
            :nationality=>r[:p_out_nationality],                
            :contact_name=>r[:p_out_con_name], 
            :contact_tel=>r[:p_out_con_tel], 
            :contact_desc=>r[:p_out_relation_desc],
            
            :address=>r[:p_out_present_address],
            :province=>r[:p_out_present_c_prov],
            
            
            :lice_addreess=>r[:p_out_lice_address],
            :lice_province=>r[:p_out_lice_c_prov],
             
            :data=>o}
            
            obj[:address] = ""
            obj[:address] += r[:p_out_present_address] if r[:p_out_present_address]
            obj[:address] += " " + r[:p_out_present_c_prov] if  r[:p_out_present_c_prov] 
            
            obj[:lice_address] = ""

            obj[:lice_address] += r[:p_out_lice_address] if r[:p_out_lice_address]
            
            obj[:lice_address] += " " + r[:p_out_lice_c_prov].to_s if  r[:p_out_lice_c_prov] 
            

present_c_prov = []                     
             present_c_prov= obj[:address].split(/[[:space:]]/).collect{|i| i.strip if i!=''}.compact if obj[:address]

             lice_c_prov=  obj[:lice_address].split(/[[:space:]]/).collect{|i| i.strip if i!=''}.compact if obj[:lice_address]

if present_c_prov.size >=4       

  obj.merge!  :contact_address=> present_c_prov[0..-5].join(" "),

:contact_tambon=> present_c_prov[-4].split('.')[-1],

:contact_amphur=> present_c_prov[-3].split('.')[-1],

:contact_province=> present_c_prov[-2].split('.')[-1],

:contact_zipcode=> present_c_prov[-1]



 end

#puts "befoer4"

 if lice_c_prov and  lice_c_prov.size >=4  

   obj.merge!  :born_address=> lice_c_prov[0..-5].join(" "),

         :born_tambon=> lice_c_prov[-4].split('.')[-1],

         :born_amphur=> lice_c_prov[-3].split('.')[-1],

         :born_province=> lice_c_prov[-2].split('.')[-1],

         :born_zipcode=> lice_c_prov[-1]



 end
            


    # response = client.call(:ws_emr_ptimage, message: { 'HN'=> hn ,'user'=> 'emr','Password'=>'1234','IPAddress'=>'170.100.50.10' })
 
    
 if false
 
     hash = response.to_hash
    # puts hash.keys.inspect

    puts hash.inspect 

     hash = hash[:ws_emr_ptimage_response]
    # puts hash.keys.inspect

     hash = hash[:ws_emr_ptimage_result]

     #data = JSON.parse(hash)['Table1'][0]['PCTNAME']
     data = hash
    # puts data 
     obj[:picture] = data if data and data.size>0
 
 end




        else

          obj = {:status=>404}

        end

        rescue Exception=>e 
           
          obj = {:error=>e.message,:trace=>e.backtrace}

        end

         puts obj.inspect 

         res = <<JSONOBJ
{
    "statuscode": 200,
    "statusmessage": "Get Patient Success!",
    "data": {
        "hn": "#{obj[:s_hn]}",
        "cid": "#{obj[:public_id]}",
        "prefix_name": "#{obj[:prefix]}",
        "fname": "#{obj[:first_name]}",
        "lname": "#{obj[:last_name]}",
        "prefix_en": "#{obj[:prefix_eng]}",
        "fname_en": "#{obj[:first_name_eng]}",
        "lname_en": "#{obj[:last_name_eng]}",
        "gender": "#{obj[:gender]}",
        "birth_date": "#{obj[:birth_date]}",
    }
}

JSONOBJ


        return JSON.parse(res)

        end


      
  end
end