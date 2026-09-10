module Oauth
  class YandexProvider < Provider
    AUTHORIZE_URL = "https://oauth.yandex.ru/authorize".freeze
    TOKEN_URL = "https://oauth.yandex.ru/token".freeze
    USER_INFO_URL = "https://login.yandex.ru/info".freeze

    def initialize(redirect_uri:)
      super
      @client_secret = Configuration.client_secret(provider_key)
      raise Error, "Яндекс ID пока не настроен" if @client_secret.blank?
    end

    def provider_key
      "yandex"
    end

    def authorization_url(state:, code_challenge:)
      params = {
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        state: state,
        code_challenge: code_challenge,
        code_challenge_method: "S256"
      }

      "#{AUTHORIZE_URL}?#{URI.encode_www_form(params)}"
    end

    def fetch_profile(code:, code_verifier:, expected_state:, callback_params:)
      token = request_json(
        URI(TOKEN_URL),
        method: :post,
        form: {
          grant_type: "authorization_code",
          code: code,
          client_id: client_id,
          client_secret: @client_secret,
          code_verifier: code_verifier
        }
      )
      access_token = token["access_token"].presence
      raise Error, "Яндекс ID не вернул access token" if access_token.blank?

      payload = request_json(
        URI("#{USER_INFO_URL}?format=json"),
        method: :get,
        headers: { "Authorization" => "OAuth #{access_token}" }
      )

      uid = payload["id"].presence
      raise Error, "Яндекс ID не вернул идентификатор пользователя" if uid.blank?

      name = payload["real_name"].to_s.strip.presence
      name ||= payload["display_name"].to_s.strip.presence
      name ||= [payload["first_name"], payload["last_name"]].compact_blank.join(" ").presence

      Profile.new(
        provider: provider_key,
        uid: uid.to_s,
        email: payload["default_email"].to_s.strip.downcase.presence || Array(payload["emails"]).first.to_s.strip.downcase.presence,
        name: name,
        phone: payload["default_phone"].to_h["number"].to_s.strip.presence,
        avatar_url: avatar_url(payload)
      )
    end

    private

    def avatar_url(payload)
      return if ActiveModel::Type::Boolean.new.cast(payload["is_avatar_empty"])

      avatar_id = payload["default_avatar_id"].to_s.presence
      avatar_id ? "https://avatars.yandex.net/get-yapic/#{avatar_id}/islands-200" : nil
    end
  end
end
