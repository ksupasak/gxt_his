require 'roo'
require 'iconv'

# m1 = get_map :marital, '1'
# m2 = get_map :nationality, '01'
# m3 = get_map :occupation,'01'
# m4 = get_map :patient_type,'02'
# m5 = get_map :prefix,'01'
# m6 = get_map :title,'aj'
# m7 = get_map :province,'961102   '

class DBMap 

attr_accessor :maps

def initialize
  
    @maps= {}
    @maps[:gender] =get_map :gender
    @maps[:marital] = get_map :marital
    # @maps[:nationality] = get_map :nationality
    @maps[:occupation] = get_map :occupation
    @maps[:patient_type] = get_map :patient_type
    # @maps[:prefix] = get_map :prefix
    # @maps[:title] = get_map :title
    # @maps[:province] = get_map :province    
    # @maps[:con_province] =   @maps[:province] 
    # @maps[:lice_province] =  @maps[:province]  
    
end

def get_values values
 begin
   result = values.clone
   values.each_pair do |k,v|
     map = @maps[k.to_sym]
     if map and v
      puts  "found #{k}"
       value = get_value k.to_s,map,v
	puts "process #{k}"
       result.merge! value if value
     else	
       result[k] = v.strip if v
     end
   end
  rescue Exception=>e
	puts e.message
   
  end 
   return result
end

def get_value t,map, v
    if v!=""
    value = map[v.strip]
    
    case t.to_s
    when :birth_date
	#25270110
      year = v[0..3]
      month = v[4..5]
	  day = v[6..7]
	  value = {:birth_date=>"#{day}/#{month}/#{year}"}	
	when 'prefix',  'title'
      value ={:prefix=>value[1].strip,:gender=>value[2]}
    else
      value = {t=>value}
    end
  
    return value
    end
    return nil
  
end


def get_map t
  
  table = t.to_s
  path = 'of_master'
  
  
  map = {}
  xls = Roo::Spreadsheet.open(File.join(path,"#{table}.xls"))
  2.upto(xls.last_row) do |index|

    row = xls.row(index)
    
    case table
    when 'province',  'prefix',  'title'
      value = row
    else
    value = row[-1]
    value = value.to_i if value.class==Float
    value = value.to_s.strip
    
    end
    
    map[row[1].strip]=value
    
  end
  map
end

end

# map = DBMap.new
# a = map.get_values :first_name=>'Supasak',:last_name=>'owkfj',:marital=>'1', :nationality=>'01',:occupation=>'01',:patient_type=>'02',:prefix=>'01',:title=>'aj',:province=>'961102',:lice_province=>'961102'
# 
# puts a.inspect

# tambon
# amphur
# zipcode

# m1 = get_map :marital, '1'
# m2 = get_map :nationality, '01'
# m3 = get_map :occupation,'01'
# m4 = get_map :patient_type,'02'
# m5 = get_map :prefix,'01'
# m6 = get_map :title,'aj'
# m7 = get_map :province,'961102   '
# puts m7



