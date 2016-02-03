require "httmultiparty"
require "json"
require "singleton"

module Rubill
  class APIError < StandardError; end

  class Session
    include HTTMultiParty
    include Singleton

    attr_accessor :id

    base_uri "https://api.bill.com/api/v2"

    def initialize
      config = self.class.configuration
      if missing = (!config.missing_keys.empty? && config.missing_keys)
        raise "Missing key(s) in configuration: #{missing}"
      end

      if config.sandbox
        self.class.base_uri "https://api-stage.bill.com/api/v2"
      end

      login
    end

    def execute(query)
      _post(query.url, query.options)
    end

    def login
      self.id = self.class.login
    end

    def self.login
      login_options = {
        password: configuration.password,
        userName: configuration.user_name,
        devKey: configuration.dev_key,
        orgId: configuration.org_id,
      }
      login = _post("/Login.json", login_options)
      login[:sessionId]
    end

    def options(data={})
      opts = {
          sessionId: id,
          devKey: self.class.configuration.dev_key,
      }

      opts[:file] = data.delete(:content) if data.has_key?(:fileName)

      opts[:data] = data.to_json

      opts
    end

    def self.default_headers
      {"Content-Type" => "application/x-www-form-urlencoded"}
    end

    def _post(url, data, retries=0)
      begin
        self.class._post(url, options(data))
      rescue APIError => e
        if e.message =~ /Session is invalid/ && retries < 3
          login
          _post(url, data, retries + 1)
        else
          raise
        end
      end
    end

    def self._post(url, options)
      if options.key?(:fileName)
        file = StringIO.new(options.delete(:content))
      end

      post_options = {
        body: options,
        headers: default_headers,
      }

      post_options[:file] = file if file

      if self.configuration.debug
        post_options[:debug_output] = $stdout
      end

      response = post(url, post_options)
      result = JSON.parse(response.body, symbolize_names: true)

      unless result[:response_status] == 0
        raise APIError.new(result[:response_data][:error_message])
      end

      result[:response_data]
    end

    def self.configuration
      Rubill::configuration
    end
  end
end
