require 'faraday_middleware'
require 'securerandom'

module Porticor
  class InvalidOptions < StandardError; end
  class Error < StandardError; end
  class DuplicateItemError < Error; end

  class Client
    attr_accessor *Configuration::VALID_OPTIONS

    def initialize(options = {})
      merged_options = ::Porticor.options.merge(options)
      unless Configuration::VALID_OPTIONS.all?{ |option| merged_options[option] }
        raise InvalidOptions.new("You must specify your Porticor api_url, api_key, and api_secret.")
      end
      Configuration::VALID_OPTIONS.each do |key|
        public_send("#{key}=", merged_options[key])
      end
    end

    # Attempts to create a protected item and if that yields a duplicate item
    # error we then attempt to update the existing value.
    def create_or_update_protected_item(name, value, metadata = nil)
      begin
        create_protected_item(name, value, metadata)
      rescue DuplicateItemError
        update_protected_item(name, value, metadata)
      end
    end

    # Fetches a protected item by name from Porticor.
    # Returns nil if not found.
    def get_protected_item(name)
      response = get("/api/protected_items/#{URI.escape(name)}", api_cred: temp_cred)
      if success?(response)
        response.body.item
      else
        nil
      end
    end

    def create_protected_item(name, value, metadata = nil)
      response = post("/api/protected_items/#{URI.escape(name)}", item: value, metadata: metadata, api_cred: temp_cred)
      if success?(response)
        value
      else
        case response.body['error_code']
        when 'CreateDuplicate'
          raise DuplicateItemError.new response.body['error']
        else
          raise Error.new response.body['error_code']
        end
      end
    end

    def update_protected_item(name, value, metadata = nil)
      response = put("/api/protected_items/#{URI.escape(name)}", item: value, metadata: metadata, api_cred: temp_cred)
      if success?(response)
        value
      else
        raise Error.new response.body['error_code']
      end
    end

    private

    def success?(response)
      response.success? && response.body['error'].empty?
    end

    def generate_nonce
      SecureRandom.hex(8)
    end

    def sign_cred_request(nonce, time)
      str_to_sign = "get_temporary_credential?api_key_id=#{api_key}&nonce=#{nonce}&time=#{time}"
      digest = OpenSSL::Digest.new('sha256')
      sig = OpenSSL::HMAC.hexdigest(digest, api_secret, str_to_sign)
      return 'hmac-sha256:' + sig
    end

    def temp_cred
      @@temp_cred ||= begin
        time = Time.now.to_i
        nonce = generate_nonce
        sig = sign_cred_request(nonce, time)
        response = get('/api/creds/get_temporary_credential',
          api_key_id: api_key,
          time: time,
          nonce: nonce,
          api_signature: sig)
        if success?(response)
          response.body.credential
        else
          nil
        end
      end
    end

    def connection
      Faraday.new(url: api_url) do |conn|
        conn.request :json
        conn.use Faraday::Response::Mashify
        conn.response :json, content_type: /\bjson$/
        conn.response :raise_error
        conn.adapter Faraday.default_adapter
      end
    end

    def get(path, options = {})
      connection.get(path, options)
    end

    # In Porticor's ridiculous world, PUT actually means POST
    def post(path, options = {})
      # They also don't actually work with POST/PUT bodies so you have
      # to embed what would normally be the body as request URL params
      # for no good reason whatsoever...
      connection.put(path) do |request|
        request.params = options
      end
    end

    # ... and POST means PUT?  WTF?
    def put(path, options = {})
      connection.post(path) do |request|
        request.params = options
      end
    end
  end
end
