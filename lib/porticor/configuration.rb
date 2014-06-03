module Porticor
  module Configuration
    VALID_OPTIONS = [ :api_key, :api_secret, :api_url ]

    attr_accessor *VALID_OPTIONS

    def configure
      yield self
    end

    def options
      Hash[ * VALID_OPTIONS.map { |key| [key, send(key)] }.flatten ]
    end
  end
end
