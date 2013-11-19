# encoding: UTF-8

require 'marc'
require 'marc/marc8/map_to_unicode'

module MARC
  module Marc8
    # NOT thread-safe, it needs to keep state as it goes through a string,
    # do not re-use between threads. 
    #
    # http://www.loc.gov/marc/specifications/speccharmarc8.html
    #
    # Uses 4 spaces per indent, rather than usual ruby 2 space, just to change the python less. 
    #
    # Returns UTF-8 encoded string! Encode to something else if you want
    # something else. 
    class ToUnicode
      BASIC_LATIN = 0x42
      ANSEL = 0x45

      G0_SET = ['(', ',', '$']
      G1_SET = [')', '-', '$']

      CODESETS = MARC::Marc8::MapToUnicode::CODESETS

      # These are state flags, MARC8 requires you to keep
      # track of 'current char sets' or something like that, which
      # are changed with escape codes, or something like that. 
      attr_accessor :g0, :g1

      def initialize
        self.g0 = BASIC_LATIN
        self.g1 = ANSEL
      end

      # Returns UTF-8 encoded string equivalent of marc8_string passed in. 
      # Raises?
      def transcode(marc8_string)
        # don't choke on empty marc8_string
        return "" if marc8_string.nil? || marc8_string.empty?
         
        # Make sure to call it 'binary', so we can slice it
        # byte by byte, and so ruby doesn't complain about bad
        # bytes for some other encoding. We'll take a dup
        # of it first, so we don't change encoding on input, mutating it. 
        marc8_string = marc8_string.dup
        marc8_string.force_encoding("binary")

        uni_list = []
        combinings = []
        pos = 0
        while pos < marc8_string.length
            if marc8_string[pos] == "\x1b"
                next_byte = marc8_string[pos+1]
                if G0_SET.include? next_byte
                    if marc8_string.length >= pos + 3
                        if marc8_string[pos+2] == ',' and next_byte == '$'
                            pos += 1
                        end
                        self.g0 = marc8_string[pos+2].ord
                        pos = pos + 3
                        next
                    else
                        # if there aren't enough remaining characters, readd
                        # the escape character so it doesn't get lost; may
                        # help users diagnose problem records
                        uni_list.push marc8_string[pos]
                        pos += 1
                        next
                    end

                elsif G1_SET.include? next_byte
                    if marc8_string[pos+2] == '-' and next_byte == '$'
                        pos += 1
                    end
                    self.g1 = marc8_string[pos+2].ord
                    pos = pos + 3
                    next
                else
                    charset = next_byte.ord
                    if CODESETS.has_key? charset
                        self.g0 = charset
                        pos += 2
                    elsif charset == 0x73
                        self.g0 = BASIC_LATIN
                        pos += 2
                        if pos == marc8_string.length
                            break
                        end
                    end
                end
            end

            mb_flag = is_multibyte(self.g0)
                
            if mb_flag
                code_point = (marc8_string[pos].ord * 65536 +
                     marc8_string[pos+1].ord * 256 +
                     marc8_string[pos+2].ord)
                pos += 3
            else
                code_point = marc8_string[pos].ord
                pos += 1
            end
                
            if (code_point < 0x20 or
                (code_point > 0x80 and code_point < 0xa0))
                uni = unichr(code_point)
                next
            end

            if code_point > 0x80 and not mb_flag
                (uni, cflag) = CODESETS[self.g1][code_point]
            else
                (uni, cflag) = CODESETS[self.g0][code_point]
            end
            
                
            if cflag
                combinings.push unichr(uni)
            else
                uni_list.push unichr(uni)
                if combinings.length > 0
                    uni_list.concat combinings
                    combinings = []
                end
            end
        end

        # what to do if combining chars left over?
        uni_str = uni_list.join('')
 
        #TODO: Normalize NFC preferred?       
            
        return uni_str
      end

      # from the original python, yeah, apparently
      # only one charset is considered multibyte
      def is_multibyte(charset)
        charset == 0x31
      end

      # input single unicode codepoint as integer; output encoded as a UTF-8 string
      # python has unichr built-in, we just define it for convenience no problem. 
      def unichr(code_point)
        [code_point].pack("U")
      end

    end
  end
end