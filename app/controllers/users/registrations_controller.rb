module Users
  class RegistrationsController < Devise::RegistrationsController
    layout "workspace", only: %i[edit update destroy]

    protected

    def build_resource(hash = {})
      super
      return unless action_name == "create"

      resource.prepare_personal_data_consent!(
        value: params.dig(:user, :personal_data_consent),
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
    end

    def update_resource(resource, params)
      remove_avatar = ActiveModel::Type::Boolean.new.cast(params[:remove_avatar])
      account_params = params.except(:remove_avatar)

      updated = if !resource.password_configured? && account_params[:password].present?
        set_first_password(resource, account_params)
      elsif !resource.password_configured? && email_changed?(resource, account_params)
        resource.errors.add(:email, "можно изменить после создания пароля")
        false
      elsif sensitive_account_update?(resource, account_params)
        resource.update_with_password(account_params)
      else
        profile_params = account_params.except(:email, :password, :password_confirmation, :current_password)
        resource.update(profile_params)
      end

      resource.avatar.purge_later if updated && remove_avatar && resource.avatar.attached?
      updated
    end

    def after_update_path_for(_resource)
      edit_user_registration_path
    end

    private

    def set_first_password(resource, params)
      if email_changed?(resource, params)
        resource.errors.add(:email, "сначала сохраните новый пароль, затем измените email")
        return false
      end

      updated = resource.update(
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
      resource.update_column(:password_configured, true) if updated
      updated
    end

    def email_changed?(resource, params)
      params[:email].present? && params[:email].to_s.strip.downcase != resource.email.to_s.downcase
    end

    def sensitive_account_update?(resource, params)
      params[:password].present? || email_changed?(resource, params)
    end
  end
end
