module Users
  class RegistrationsController < Devise::RegistrationsController
    layout "workspace_new_design", only: %i[edit update destroy]

    protected

    def update_resource(resource, params)
      if sensitive_account_update?(resource, params)
        resource.update_with_password(params)
      else
        profile_params = params.except(:email, :password, :password_confirmation, :current_password)
        resource.update(profile_params)
      end
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
