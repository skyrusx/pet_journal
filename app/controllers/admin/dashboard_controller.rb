class Admin::DashboardController < Admin::ApplicationController
  def index
    @users_count = User.count
    @pets_count = Pet.count
    @events_count = PetEvent.count
    @new_users_count = User.where(created_at: 7.days.ago..Time.current).count
    @recent_users = User.includes(:pets).order(created_at: :desc).limit(8)
  end
end
