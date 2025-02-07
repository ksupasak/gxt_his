# Base class/interface
class BaseHandler
  def get_patient_info params
    raise NotImplementedError, "Subclasses must implement the 'execute' method"
  end
end