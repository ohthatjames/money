#encoding: utf-8

class Money
  module Parsing
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Parses the current string and converts it to a +Money+ object.
      # Excess characters will be discarded.
      #
      # @param [String, #to_s] input The input to parse.
      # @param [Currency, String, Symbol] currency The currency format.
      #   The currency to set the resulting +Money+ object to.
      #
      # @return [Money]
      #
      # @raise [ArgumentError] If any +currency+ is supplied and
      #   given value doesn't match the one extracted from
      #   the +input+ string.
      #
      # @example
      #   '100'.to_money                #=> #<Money @fractional=10000>
      #   '100.37'.to_money             #=> #<Money @fractional=10037>
      #   '100 USD'.to_money            #=> #<Money @fractional=10000, @currency=#<Money::Currency id: usd>>
      #   'USD 100'.to_money            #=> #<Money @fractional=10000, @currency=#<Money::Currency id: usd>>
      #   '$100 USD'.to_money           #=> #<Money @fractional=10000, @currency=#<Money::Currency id: usd>>
      #   'hello 2000 world'.to_money   #=> #<Money @fractional=200000 @currency=#<Money::Currency id: usd>>
      #
      # @example Mismatching currencies
      #   'USD 2000'.to_money("EUR")    #=> ArgumentError
      #
      # @see Money.from_string
      #
      def parse(input, *currency_and_locale)
        currency, locale = process_currency_and_locale(currency_and_locale)
        i = input.to_s.strip

        currency = negotiate_currency(currency, implied_currency(i))
        currency = Money::Currency.wrap(currency)

        locale = Money::Locale.wrap(locale)

        fractional = extract_cents(i, currency, locale)
        new(fractional, currency)
      end
      
      # Converts a String into a Money object treating the +value+
      # as amount and converting to fractional unit,
      # according to +currency+ subunit property,
      # before instantiating the Money object.
      #
      # Behind the scenes, this method relies on {Money.from_bigdecimal}
      # to avoid problems with string-to-numeric conversion.
      #
      # @param [String, #to_s] value The money amount, in dollars.
      # @param [Currency, String, Symbol] currency
      #   The currency to set the resulting +Money+ object to.
      #
      # @return [Money]
      #
      # @example
      #   Money.from_string("100")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_string("100", "USD")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_string("100", "EUR")
      #   #=> #<Money @fractional=10000 @currency="EUR">
      #   Money.from_string("100", "BHD")
      #   #=> #<Money @fractional=100 @currency="BHD">
      #
      # @see String#to_money
      # @see Money.parse
      #
      def from_string(value, currency = Money.default_currency)
        from_bigdecimal(BigDecimal.new(value.to_s), currency)
      end

      # Converts a Fixnum into a Money object treating the +value+
      # as amount and to corresponding fractional unit,
      # according to +currency+ subunit property,
      # before instantiating the Money object.
      #
      # @param [Fixnum] value The money amount, in dollars.
      # @param [Currency, String, Symbol] currency The currency format.
      #
      # @return [Money]
      #
      # @example
      #   Money.from_fixnum(100)
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_fixnum(100, "USD")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_fixnum(100, "EUR")
      #   #=> #<Money @fractional=10000 @currency="EUR">
      #   Money.from_fixnum(100, "BHD")
      #   #=> #<Money @fractional=100 @currency="BHD">
      #
      # @see Fixnum#to_money
      # @see Money.from_numeric
      #
      def from_fixnum(value, currency = Money.default_currency)
        currency = Money::Currency.wrap(currency)
        amount   = value * currency.subunit_to_unit
        new(amount, currency)
      end

      # Converts a Float into a Money object treating the +value+
      # as dollars and to corresponding fractional unit,
      # according to +currency+ subunit property,
      # before instantiating the Money object.
      #
      # Behind the scenes, this method relies on Money.from_bigdecimal
      # to avoid problems with floating point precision.
      #
      # @param [Float] value The money amount, in dollars.
      # @param [Currency, String, Symbol] currency The currency format.
      #
      # @return [Money]
      #
      # @example
      #   Money.from_float(100.0)
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_float(100.0, "USD")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_float(100.0, "EUR")
      #   #=> #<Money @fractional=10000 @currency="EUR">
      #   Money.from_float(100.0, "BHD")
      #   #=> #<Money @fractional=100 @currency="BHD">
      #
      # @see Float#to_money
      # @see Money.from_numeric
      #
      def from_float(value, currency = Money.default_currency)
        from_bigdecimal(BigDecimal.new(value.to_s), currency)
      end

      # Converts a BigDecimal into a Money object treating the +value+
      # as dollars and converting to corresponding fractional unit,
      # according to +currency+ subunit property,
      # before instantiating the Money object.
      #
      # @param [BigDecimal] value The money amount, in dollars.
      # @param [Currency, String, Symbol] currency The currency format.
      #
      # @return [Money]
      #
      # @example
      #   Money.from_bigdecimal(BigDecimal.new("100")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_bigdecimal(BigDecimal.new("100", "USD")
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_bigdecimal(BigDecimal.new("100", "EUR")
      #   #=> #<Money @fractional=10000 @currency="EUR">
      #   Money.from_bigdecimal(BigDecimal.new("100", "BHD")
      #   #=> #<Money @fractional=100 @currency="BHD">
      #
      # @see BigDecimal#to_money
      # @see Money.from_numeric
      #
      def from_bigdecimal(value, currency = Money.default_currency)
        currency = Money::Currency.wrap(currency)
        amount   = value * currency.subunit_to_unit
        new(amount.round, currency)
      end

      # Converts a Numeric value into a Money object treating the +value+
      # as dollars and converting to corresponding fractional unit,
      # according to +currency+ subunit property,
      # before instantiating the Money object.
      #
      # This method relies on various +Money.from_*+ methods
      # and tries to forwards the call to the most appropriate method
      # in order to reduce computation effort.
      # For instance, if +value+ is an Integer, this method calls
      # {Money.from_fixnum} instead of using the default
      # {Money.from_bigdecimal} which adds the overload to converts
      # the value into a slower BigDecimal instance.
      #
      # @param [Numeric] value The money amount, in dollars.
      # @param [Currency, String, Symbol] currency The currency format.
      #
      # @return [Money]
      #
      # @raise +ArgumentError+ Unless +value+ is a supported type.
      #
      # @example
      #   Money.from_numeric(100)
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_numeric(100.00)
      #   #=> #<Money @fractional=10000 @currency="USD">
      #   Money.from_numeric("100")
      #   #=> ArgumentError
      #
      # @see Numeric#to_money
      # @see Money.from_fixnum
      # @see Money.from_float
      # @see Money.from_bigdecimal
      #
      def from_numeric(value, currency = Money.default_currency)
        case value
        when Fixnum
          from_fixnum(value, currency)
        when Numeric
          from_bigdecimal(BigDecimal.new(value.to_s), currency)
        else
          raise ArgumentError, "`value' should be a Numeric object"
        end
      end

      # Takes a number string and attempts to massage out the number.
      #
      # @param [String] input The string containing a potential number.
      #
      # @return [Integer]
      #
      def extract_cents(input, currency, locale)
        # remove anything that's not a number, potential thousands_separator, or minus sign
        num = input.gsub(/[^\d.,'-]/, '')

        # set a boolean flag for if the number is negative or not
        negative = num =~ /^-|-$/ ? true : false

        # decimal mark character
        decimal_char = currency.decimal_mark

        # if negative, remove the minus sign from the number
        # if it's not negative, the hyphen makes the value invalid
        if negative
          num = num.sub(/^-|-$/, '')
        end

        raise ArgumentError, "Invalid currency amount (hyphen)" if num.include?('-')

        #if the number ends with punctuation, just throw it out.  If it means decimal,
        #it won't hurt anything.  If it means a literal period or comma, this will
        #save it from being mis-interpreted as a decimal.
        num.chop! if num.match(/[\.|,]$/)

        parts = num.gsub(locale.thousands_separator, '').split(locale.decimal_separator)
        raise "Too many parts " if parts.size > 2
        major, minor = parts
        minor ||= 0
        
        # build the string based on major/minor since decimal_mark/thousands_separator have been removed
        # avoiding floating point arithmetic here to ensure accuracy
        cents = (major.to_i * currency.subunit_to_unit)
        # Because of an bug in JRuby, we can't just call #floor
        minor = minor.to_s
        minor = if minor.size < currency.decimal_places
                  (minor + ("0" * currency.decimal_places))[0,currency.decimal_places].to_i
                elsif minor.size > currency.decimal_places
                  if minor[currency.decimal_places,1].to_i >= 5
                    minor[0,currency.decimal_places].to_i+1
                  else
                    minor[0,currency.decimal_places].to_i
                  end
                else
                  minor.to_i
                end
        cents += minor

        # if negative, multiply by -1; otherwise, return positive cents
        negative ? cents * -1 : cents
      end
      
      # Check the first character for a currency symbol, alternatively get it
      # from the stated currency string
      def implied_currency(input)
        if Money.assume_from_symbol && input =~ /^(\$|€|£)/
          case input
          when /^\$/ then "USD"
          when /^€/ then "EUR"
          when /^£/ then "GBP"
          end
        else
          input[/[A-Z]{2,3}/]
        end
      end
      
      # check that currency passed and embedded currency are the same,
      # and negotiate the final currency
      def negotiate_currency(currency, c)
        if currency.nil? and c.nil?
          currency = Money.default_currency
        elsif currency.nil?
          c
        elsif c.nil? || currency == c
          currency
        else
          # TODO: ParseError
          raise ArgumentError, "Mismatching Currencies"
        end
      end
      
      def process_currency_and_locale(currency_and_locale)
        case currency_and_locale.size
        when 0
          [nil, nil]
        when 1
          if currency_and_locale.first.nil?
            [nil, nil]
          elsif currency_and_locale.first.is_a?(Currency) || currency_and_locale.first.size == 3
            currency_and_locale + [nil]
          else
            [nil] + currency_and_locale
          end
        when 2
          currency_and_locale
        else
          raise ArgumentError "Too many arguments"
        end
      end
    end
  end
end
