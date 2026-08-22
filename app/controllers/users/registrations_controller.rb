module Users
  class RegistrationsController < Devise::RegistrationsController
    layout "workspace_new_design", only: %i[edit update destroy]

    protected

    def update_resource(resource, params)
      remove_avatar = ActiveModel::Type::Boolean.new.cast(params[:remove_avatar])
      account_params = params.except(:remove_avatar)

      updated = if sensitive_account_update?(resource, account_params)
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

    def sensitive_account_update?(resource, params)
      params[:password].present? ||
        (params[:email].present? && params[:email].to_s.strip.downcase != resource.email.to_s.downcase)
    end
  end
end
