require_relative 'his_interface'
require 'json'

class MOCKGateway < BaseHandler
  def get_patient_info params
    puts "SNH Gateway executed!"
    content = File.open(File.join("example","pattest.json")).read.strip
    object = JSON.parse(content)
    object['data']['hn'] = params[:hn]
    return object
  end
end