class Money
  class Locale
    attr_reader :decimal_separator, :thousands_separator

    def initialize(decimal_separator, thousands_separator)
      @decimal_separator, @thousands_separator = decimal_separator, thousands_separator
    end

    def self.default
      new('.', ',')
    end

    def self.default_options
      {
        :decimal_separator => '.',
        :thousands_separator => ','
      }
    end

    def self.wrap(locale)
      return locale if locale.is_a?(Locale)
      options = LOCALES[locale.to_s] || default_options
      new(options[:decimal_separator], options[:thousands_separator])
    end

    LOCALES = {
      "DE" => {
        :decimal_separator => ',',
        :thousands_separator => '.'
      }
    }
  end
end
