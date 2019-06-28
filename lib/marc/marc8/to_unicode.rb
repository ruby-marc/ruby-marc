# encoding: UTF-8

require 'marc'
require 'marc/marc8/map_to_unicode'
require 'unf/normalizer'

module MARC
  module Marc8
    # Class to convert Marc8 to UTF-8. NOTE: Requires ruby 1.9+ (this could be
    # changed without too much trouble, but we just don't care to support 1.8.7 anymore.)
    #
    # http://www.loc.gov/marc/specifications/speccharmarc8.html
    #
    # NOT thread-safe, it needs to keep state as it goes through a string,
    # do not re-use between threads.
    #
    # Uses 4 spaces per indent, rather than usual ruby 2 space, just to change the python less.
    #
    # Returns UTF-8 encoded string! Encode to something else if you want
    # something else.
    #
    # III proprietary code points?
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
      #
      # Bad Marc8 bytes?  By default will raise an Encoding::InvalidByteSequenceError
      # (will not have full metadata filled out, but will have a decent error message)
      #
      # Set option :invalid => :replace to instead silently replace bad bytes
      # with a replacement char -- by default Unicode Replacement Char, but can set
      # option :replace to something else, including empty string.
      #
      # converter.transcode(bad_marc8, :invalid => :replace, :replace => "")
      #
      # By default returns NFC normalized, but set :normalization option to:
      #    :nfd, :nfkd, :nfkc, :nfc, or nil. Set to nil for higher performance,
      #    we won't do any normalization just take it as it comes out of the
      #    transcode algorithm. This will generally NOT be composed.
      #
      # By default, escaped unicode 'named character references' in Marc8 will
      # be translated to actual UTF8. Eg. "&#x200F;" But pass :expand_ncr => false
      # to disable. http://www.loc.gov/marc/specifications/speccharconversion.html#lossless
      #
      # String arg passed in WILL have it's encoding tagged 'binary' if
      # it's not already, if it's Marc8 there's no good reason for it not to
      # be already.
      def transcode(marc8_string, options = {})
        invalid_replacement     = options.fetch(:replace, "\uFFFD")
        expand_ncr              = options.fetch(:expand_ncr, true)
        normalization           = options.fetch(:normalization, :nfc)


        # don't choke on empty marc8_string
        return "" if marc8_string.nil? || marc8_string.empty?

        # Make sure to call it 'binary', so we can slice it
        # byte by byte, and so ruby doesn't complain about bad
        # bytes for some other encoding. Yeah, we're changing
        # encoding on input! If it's Marc8, it ought to be tagged
        # binary already.
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

            begin
              code_set = (code_point > 0x80 and not mb_flag) ? self.g1 : self.g0
              (uni, cflag) = CODESETS.fetch(code_set).fetch(code_point)

              if cflag
                  combinings.push unichr(uni)
              else
                  uni_list.push unichr(uni)
                  if combinings.length > 0
                      uni_list.concat combinings
                      combinings = []
                  end
              end
            rescue KeyError
              if options[:invalid] == :replace
                # Let's coallesece multiple replacements
                uni_list.push invalid_replacement unless uni_list.last == invalid_replacement
                pos += 1
              else
                raise Encoding::InvalidByteSequenceError.new("MARC8, input byte offset #{pos}, code set: 0x#{code_set.to_s(16)}, code point: 0x#{code_point.to_s(16)}, value: #{transcode(marc8_string, :invalid => :replace, :replace => "�")}")
              end
            end
        end

        # what to do if combining chars left over?
        uni_str = uni_list.join('')

        if expand_ncr
          uni_str.gsub!(/&#x([0-9A-F]{4,6});/) do
            [$1.hex].pack("U")
          end
        end

        if normalization
          uni_str = UNF::Normalizer.normalize(uni_str, normalization)
        end

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
