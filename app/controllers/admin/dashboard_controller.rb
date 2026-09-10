module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        users: admin_metric(User),
        pets: admin_metric(Pet),
        pet_tags: admin_metric(PetTag)
      }
      @recent_users = User.with_attached_avatar.order(created_at: :desc).limit(5)
    end

    private

    def admin_metric(model)
      current_period_start = 7.days.ago
      previous_period_start = 14.days.ago

      recent_count = model.where(created_at: current_period_start..).count
      previous_count = model.where(created_at: previous_period_start...current_period_start).count
      change_percent = if previous_count.positive?
                         (((recent_count - previous_count).to_f / previous_count) * 100).round
                       end

      {
        total: model.count,
        recent: recent_count,
        change_percent: change_percent
      }
    end
  end
end
