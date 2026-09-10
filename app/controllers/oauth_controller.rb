require "base64"
require "digest"
require "securerandom"

class OauthController < ApplicationController
  FLOW_TTL = 10.minutes
  PENDING_TTL = 15.minutes
  PURPOSES = %w[login link disconnect].freeze

  before_action :set_provider, only: %i[start callback]

  def start
    purpose = oauth_purpose
    session.delete(:oauth_pending)
    return redirect_to(new_user_session_path, alert: "Сначала войдите в PetJournal") if protected_purpose?(purpose) && !user_signed_in?

    if purpose == "disconnect"
      identity = current_user.external_identities.find_by(provider: @provider)
      return redirect_to(edit_user_registration_path, alert: "Этот способ входа не подключён") unless identity
      unless current_user.can_disconnect_external_identity?(identity)
        return redirect_to(edit_user_registration_path, alert: "Сначала создайте пароль или подключите другой способ входа")
      end
    end

    state = SecureRandom.urlsafe_base64(32)
    code_verifier = SecureRandom.urlsafe_base64(48)
    callback_url = oauth_callback_url(provider: @provider)
    client = Oauth::Provider.build(@provider, redirect_uri: callback_url)

    session[:oauth_flow] = {
      "provider" => @provider,
      "purpose" => purpose,
      "state" => state,
      "code_verifier" => code_verifier,
      "user_id" => user_signed_in? ? current_user.id : nil,
      "started_at" => Time.current.to_i
    }

    redirect_to client.authorization_url(state: state, code_challenge: pkce_challenge(code_verifier)), allow_other_host: true
  rescue Oauth::Provider::Error => e
    redirect_to oauth_failure_path(purpose), alert: e.message
  end

  def callback
    flow = session.delete(:oauth_flow).to_h
    purpose = flow["purpose"].presence_in(PURPOSES) || "login"

    validate_flow!(flow)
    validate_state!(flow.fetch("state"))
    raise Oauth::Provider::Error, provider_error_message if params[:error].present?
    raise Oauth::Provider::Error, "OAuth-провайдер не вернул код авторизации" if params[:code].blank?

    callback_url = oauth_callback_url(provider: @provider)
    profile = Oauth::Provider.build(@provider, redirect_uri: callback_url).fetch_profile(
      code: params[:code].to_s,
      code_verifier: flow.fetch("code_verifier"),
      expected_state: flow.fetch("state"),
      callback_params: params.to_unsafe_h
    )

    case purpose
    when "link"
      link_identity(profile, flow)
    when "disconnect"
      disconnect_identity(profile, flow)
    else
      sign_in_or_prepare_registration(profile)
    end
  rescue KeyError, Oauth::Provider::Error => e
    redirect_to oauth_failure_path(purpose), alert: e.message
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("OAuth callback failed: #{e.class}: #{e.message}")
    redirect_to oauth_failure_path(purpose), alert: "Не удалось завершить OAuth-вход. Попробуйте ещё раз."
  end

  def complete
    @profile = pending_profile
    return if @profile

    redirect_to new_user_session_path, alert: "Сессия регистрации истекла. Попробуйте войти через внешний сервис ещё раз."
  end

  def register
    @profile = pending_profile
    unless @profile
      return redirect_to new_user_session_path, alert: "Сессия регистрации истекла. Попробуйте ещё раз."
    end

    unless params[:personal_data_consent] == "1"
      flash.now[:alert] = "Для создания аккаунта необходимо согласие на обработку персональных данных."
      return render :complete, status: :unprocessable_entity
    end

    if @profile.email.blank?
      session.delete(:oauth_pending)
      return redirect_to new_user_registration_path, alert: "Провайдер не передал email. Зарегистрируйтесь по email или повторите вход с доступом к почте."
    end

    if user_with_email(@profile.email)
      session.delete(:oauth_pending)
      return redirect_to new_user_session_path, alert: existing_email_message(@profile.provider)
    end

    user = create_oauth_user!(@profile)
    session.delete(:oauth_pending)
    Oauth::ProfileImporter.new(user, @profile).call
    sign_in(:user, user)
    redirect_to after_sign_in_path_for(user), notice: "Аккаунт создан через #{Oauth::Configuration.provider_name(@profile.provider)}."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("OAuth registration failed: #{e.class}: #{e.message}")
    flash.now[:alert] = "Не удалось создать аккаунт. Проверьте данные и попробуйте ещё раз."
    render :complete, status: :unprocessable_entity
  end

  private

  def set_provider
    @provider = params[:provider].to_s
    raise ActionController::RoutingError, "Not Found" unless Oauth::Configuration::PROVIDERS.include?(@provider)
  end

  def oauth_purpose
    requested = params[:purpose].to_s.presence_in(PURPOSES)
    return "disconnect" if requested == "disconnect"
    return "link" if user_signed_in?

    "login"
  end

  def protected_purpose?(purpose)
    %w[link disconnect].include?(purpose)
  end

  def validate_flow!(flow)
    raise Oauth::Provider::Error, "OAuth-сессия истекла. Попробуйте ещё раз." if flow.blank?
    raise Oauth::Provider::Error, "OAuth-сессия повреждена. Попробуйте ещё раз." unless flow["provider"] == @provider

    started_at = Time.zone.at(flow.fetch("started_at").to_i)
    raise Oauth::Provider::Error, "OAuth-сессия истекла. Попробуйте ещё раз." if started_at < FLOW_TTL.ago

    if protected_purpose?(flow["purpose"])
      unless user_signed_in? && current_user.id == flow["user_id"].to_i
        raise Oauth::Provider::Error, "Сессия PetJournal изменилась. Повторите действие."
      end
    end
  end

  def validate_state!(expected_state)
    actual_state = params[:state].to_s
    valid = actual_state.bytesize == expected_state.to_s.bytesize &&
            ActiveSupport::SecurityUtils.secure_compare(actual_state, expected_state.to_s)
    raise Oauth::Provider::Error, "Не удалось проверить OAuth state. Повторите вход." unless valid
  end

  def pkce_challenge(code_verifier)
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end

  def provider_error_message
    params[:error_description].to_s.presence || "Авторизация у внешнего сервиса была отменена или завершилась ошибкой."
  end

  def sign_in_or_prepare_registration(profile)
    identity = ExternalIdentity.find_by(provider: profile.provider, uid: profile.uid)
    if identity
      identity.update!(last_used_at: Time.current)
      Oauth::ProfileImporter.new(identity.user, profile).call
      sign_in(:user, identity.user)
      return redirect_to after_sign_in_path_for(identity.user), notice: "Вы вошли через #{identity.provider_name}."
    end

    if profile.email.blank?
      return redirect_to new_user_registration_path, alert: "Провайдер не передал email. Разрешите доступ к почте или зарегистрируйтесь по email."
    end

    if user_with_email(profile.email)
      return redirect_to new_user_session_path, alert: existing_email_message(profile.provider)
    end

    session[:oauth_pending] = profile.to_session.merge("created_at" => Time.current.to_i)
    redirect_to oauth_complete_path
  end

  def link_identity(profile, flow)
    validate_protected_user!(flow)
    identity = ExternalIdentity.find_by(provider: profile.provider, uid: profile.uid)

    if identity && identity.user_id != current_user.id
      return redirect_to edit_user_registration_path, alert: "Этот #{identity.provider_name} уже привязан к другому аккаунту PetJournal."
    end

    identity ||= current_user.external_identities.find_or_initialize_by(provider: profile.provider)
    if identity.persisted? && identity.uid != profile.uid
      return redirect_to edit_user_registration_path, alert: "К аккаунту уже подключён другой #{identity.provider_name}. Сначала отключите его."
    end

    identity.uid = profile.uid
    identity.connected_at ||= Time.current
    identity.last_used_at = Time.current
    identity.save!
    Oauth::ProfileImporter.new(current_user, profile).call

    redirect_to edit_user_registration_path, notice: "#{identity.provider_name} подключён. Теперь через него можно входить в PetJournal."
  end

  def disconnect_identity(profile, flow)
    validate_protected_user!(flow)
    identity = current_user.external_identities.find_by(provider: profile.provider)
    raise Oauth::Provider::Error, "Этот способ входа уже отключён" unless identity
    raise Oauth::Provider::Error, "Подтверждён другой аккаунт провайдера" unless identity.uid == profile.uid
    unless current_user.can_disconnect_external_identity?(identity)
      raise Oauth::Provider::Error, "Нельзя отключить последний способ входа. Сначала создайте пароль или подключите другой сервис."
    end

    provider_name = identity.provider_name
    identity.destroy!
    redirect_to edit_user_registration_path, notice: "#{provider_name} отключён от аккаунта."
  end

  def validate_protected_user!(flow)
    return if user_signed_in? && current_user.id == flow["user_id"].to_i

    raise Oauth::Provider::Error, "Сессия PetJournal изменилась. Повторите действие."
  end

  def pending_profile
    data = session[:oauth_pending].to_h
    return if data.blank?
    if Time.zone.at(data["created_at"].to_i) < PENDING_TTL.ago
      session.delete(:oauth_pending)
      return
    end

    Oauth::Profile.from_session(data)
  end

  def create_oauth_user!(profile)
    User.transaction do
      password = SecureRandom.urlsafe_base64(36)
      user = User.new(
        email: profile.email.to_s.strip.downcase,
        name: profile.name.to_s.strip.first(80).presence,
        phone: profile.phone.to_s.strip.first(32).presence,
        password: password,
        password_confirmation: password,
        password_configured: false
      )
      user.prepare_personal_data_consent!(
        value: params[:personal_data_consent],
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        source: "oauth_registration",
        metadata: { "oauth_provider" => profile.provider }
      )
      user.save!
      user.external_identities.create!(
        provider: profile.provider,
        uid: profile.uid,
        connected_at: Time.current,
        last_used_at: Time.current
      )
      user
    end
  end

  def user_with_email(email)
    User.where("LOWER(email) = ?", email.to_s.strip.downcase).first
  end

  def existing_email_message(provider)
    provider_name = Oauth::Configuration.provider_name(provider)
    "Аккаунт с таким email уже есть. Войдите обычным способом и подключите #{provider_name} в профиле."
  end

  def oauth_failure_path(purpose)
    protected_purpose?(purpose) && user_signed_in? ? edit_user_registration_path : new_user_session_path
  end
end
