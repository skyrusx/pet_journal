module Oauth
  class VkProvider < Provider
    AUTHORIZE_URL = "https://id.vk.com/authorize".freeze
    TOKEN_URL = "https://id.vk.com/oauth2/auth".freeze
    USER_INFO_URL = "https://id.vk.com/oauth2/user_info".freeze
    SCOPE = "email phone".freeze

    def provider_key
      "vk"
    end

    def authorization_url(state:, code_challenge:)
      params = {
        response_type: "code",
        client_id: client_id,
        redirect_uri: redirect_uri,
        state: state,
        code_challenge: code_challenge,
        code_challenge_method: "S256",
        scope: SCOPE
      }

      "#{AUTHORIZE_URL}?#{URI.encode_www_form(params)}"
    end

    def fetch_profile(code:, code_verifier:, expected_state:, callback_params:)
      device_id = callback_params["device_id"].presence
      raise Error, "VK ID не вернул device_id" if device_id.blank?

      token_uri = URI(TOKEN_URL)
      token_uri.query = URI.encode_www_form(
        grant_type: "authorization_code",
        redirect_uri: redirect_uri,
        client_id: client_id,
        code_verifier: code_verifier,
        state: expected_state,
        device_id: device_id
      )
      token = request_json(token_uri, method: :post, form: { code: code })

      if token["state"].present?
        returned_state = token["state"].to_s
        expected = expected_state.to_s
        state_matches = returned_state.bytesize == expected.bytesize &&
                        ActiveSupport::SecurityUtils.secure_compare(returned_state, expected)
        raise Error, "VK ID вернул неверный state" unless state_matches
      end

      access_token = token["access_token"].presence
      raise Error, "VK ID не вернул access token" if access_token.blank?

      info_uri = URI(USER_INFO_URL)
      info_uri.query = URI.encode_www_form(client_id: client_id)
      payload = request_json(info_uri, method: :post, form: { access_token: access_token })
      user = payload.fetch("user", {})

      uid = user["user_id"].presence || user["id"].presence
      raise Error, "VK ID не вернул идентификатор пользователя" if uid.blank?

      Profile.new(
        provider: provider_key,
        uid: uid.to_s,
        email: user["email"].to_s.strip.downcase.presence,
        name: [user["first_name"], user["last_name"]].compact_blank.join(" ").presence,
        phone: user["phone"].to_s.strip.presence,
        avatar_url: user["avatar"].to_s.presence || user["avatar_url"].to_s.presence
      )
    end
  end
end
