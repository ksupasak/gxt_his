require 'sinatra'
require 'json'
require 'puma'


set :port, 8001

set :bind, '0.0.0.0'
set :server, 'puma'

# Enable SSL in Puma
ssl_options = {
  cert: File.expand_path('config/cert.pem', __dir__),
  key: File.expand_path('config/key.pem', __dir__),
  verify_mode: OpenSSL::SSL::VERIFY_NONE
}

Puma::Server.class_eval do
  def self.default_options
    super.merge(
      bind: "ssl://0.0.0.0:3000?key=#{ssl_options[:key]}&cert=#{ssl_options[:cert]}"
    )
  end
end


post '/pts/smartems/Generate/gettoken' do
  content_type :json
  {
    "access_token": "mock-62TtQY7TZMdK37iukVmi3fwFk",
    "token_type": "bearer",
    "expires_in": 599
  }.to_json
end

get '/pts/smartems/api/getPatientInfo' do
  hn = params['hn']
  content_type :json
  {
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
end
