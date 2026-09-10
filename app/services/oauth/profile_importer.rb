require "net/http"
require "stringio"
require "timeout"
require "uri"

module Oauth
  class ProfileImporter
    MAX_REDIRECTS = 2

    def initialize(user, profile)
      @user = user
      @profile = profile
    end

    def call
      import_blank_profile_fields
      import_avatar
      user
    end

    private

    attr_reader :user, :profile

    def import_blank_profile_fields
      attributes = {}
      attributes[:name] = profile.name.to_s.strip.first(80) if user.name.blank? && profile.name.present?
      attributes[:phone] = profile.phone.to_s.strip.first(32) if user.phone.blank? && profile.phone.present?
      user.update!(attributes) if attributes.any?
    end

    def import_avatar
      return if user.avatar.attached? || profile.avatar_url.blank?

      response = fetch_avatar(URI.parse(profile.avatar_url.to_s))
      return unless response.is_a?(Net::HTTPSuccess)

      content_type = response["Content-Type"].to_s.split(";").first
      return unless User::AVATAR_CONTENT_TYPES.include?(content_type)

      body = response.body.to_s
      return if body.bytesize > User::AVATAR_MAX_SIZE

      extension = { "image/jpeg" => "jpg", "image/png" => "png", "image/webp" => "webp" }.fetch(content_type)
      user.avatar.attach(
        io: StringIO.new(body),
        filename: "#{profile.provider}-avatar.#{extension}",
        content_type: content_type
      )
    rescue URI::InvalidURIError, Timeout::Error, SocketError, SystemCallError, KeyError, ActiveRecord::RecordInvalid => e
      Rails.logger.warn("OAuth avatar import skipped for user #{user.id}: #{e.class}: #{e.message}")
    end

    def fetch_avatar(uri, redirects_left: MAX_REDIRECTS)
      raise URI::InvalidURIError, "avatar URL must use HTTPS" unless uri.is_a?(URI::HTTPS)

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: 5,
        read_timeout: 8
      ) { |http| http.get(uri.request_uri) }

      if response.is_a?(Net::HTTPRedirection) && redirects_left.positive?
        return fetch_avatar(URI.join(uri, response["location"]), redirects_left: redirects_left - 1)
      end

      response
    end
  end
end
