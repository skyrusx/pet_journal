module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        users: User.count,
        pets: Pet.count,
        pet_tags: PetTag.count
      }
      @recent_users = User.with_attached_avatar.order(created_at: :desc).limit(5)
    end
  end
end
