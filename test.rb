require_relative "his/his_factory"
# Example usage:
condition = ARGV[0] || "MOCK"  # Get condition from command-line argument or default to "A"
handler = HISFactory.get_handler(condition)
result = handler.get_patient_info :hn=>'1232333'

puts result