module Oauth
  Profile = Struct.new(:provider, :uid, :email, :name, :phone, :avatar_url, keyword_init: true) do
    def to_session
      {
        "provider" => provider,
        "uid" => uid,
        "email" => email,
        "name" => name,
        "phone" => phone,
        "avatar_url" => avatar_url
      }
    end

    def self.from_session(data)
      data = data.to_h
      new(
        provider: data["provider"],
        uid: data["uid"],
        email: data["email"],
        name: data["name"],
        phone: data["phone"],
        avatar_url: data["avatar_url"]
      )
    end
  end
end
