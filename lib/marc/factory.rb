module MARC
  class Factory

    def self.record
      Record
    end

    def self.data_field
      DataField
    end

    def self.subfield
      Subfield
    end

    def self.control_field
      ControlField
    end

    def self.leader
      String
    end
  end
end