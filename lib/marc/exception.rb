module MARC

  # basic exception class for exceptions that
  # can occur during MARC processing.

  class Exception < RuntimeError
  end

  class RecordException < Exception
    attr_reader :record

    def initialize(record)
      @record = record
      super(@record.errors.join(', '))
    end
  end
end
