class HISFactory
  def self.get_handler(his)
    
    case his
    when "PYTS"
      require_relative 'his_pyts'
      PYTSGateway.new
    when "SNH"
      require_relative 'his_snh'
      SNHGateway.new
    when "MOCK"
      require_relative 'his_mock'
      MOCKGateway.new
    else
      raise "Unknown handler type: #{his}"
    end
  end
end

