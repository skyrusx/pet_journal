require "json"
require "net/http"
require "timeout"
require "uri"

module Oauth
  class Provider
    class Error < StandardError; end

    attr_reader :client_id, :redirect_uri

    def self.build(provider, redirect_uri:)
      case provider.to_s
      when "vk"
        VkProvider.new(redirect_uri: redirect_uri)
      when "yandex"
        YandexProvider.new(redirect_uri: redirect_uri)
      else
        raise Error, "Неподдерживаемый OAuth-провайдер"
      end
    end

    def initialize(redirect_uri:)
      @redirect_uri = redirect_uri
      @client_id = Configuration.client_id(provider_key)
      raise Error, "#{Configuration.provider_name(provider_key)} пока не настроен" if @client_id.blank?
    end

    private

    def request_json(uri, method:, form: nil, headers: {})
      request = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
      headers.each { |key, value| request[key] = value }
      request.set_form_data(form) if form.present?

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 8
      ) { |http| http.request(request) }

      payload = JSON.parse(response.body.to_s)
      unless response.is_a?(Net::HTTPSuccess) && payload["error"].blank?
        message = payload["error_description"].presence || payload["message"].presence || payload["error"].presence
        raise Error, message || "OAuth-провайдер вернул ошибку"
      end

      payload
    rescue JSON::ParserError
      raise Error, "OAuth-провайдер вернул некорректный ответ"
    rescue Timeout::Error, SocketError, SystemCallError => e
      Rails.logger.warn("OAuth #{provider_key} request failed: #{e.class}: #{e.message}")
      raise Error, "Не удалось связаться с OAuth-провайдером"
    end
  end
end
