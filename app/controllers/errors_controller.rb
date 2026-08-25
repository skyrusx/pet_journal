require "uri"

class ErrorsController < ApplicationController
  ERROR_PAGES = {
    404 => {
      title: "Такой страницы нет",
      text: "Возможно, ссылка устарела или адрес введён с ошибкой.",
      image: "/petjournal/errors/error-404.webp?v=14",
      primary_label: "На главную",
      secondary_label: "Вернуться назад"
    },
    422 => {
      title: "Не удалось выполнить действие",
      text: "Обновите страницу и попробуйте ещё раз.",
      image: "/petjournal/errors/error-422.webp?v=14",
      primary_label: "На главную",
      secondary_label: "Вернуться назад"
    },
    500 => {
      title: "Что-то пошло не так",
      text: "Мы не смогли открыть эту страницу. Попробуйте немного позже.",
      image: "/petjournal/errors/error-500.webp?v=14",
      primary_label: "Попробовать снова",
      secondary_label: "На главную"
    },
    406 => {
      title: "Ваш браузер нужно обновить",
      text: "PetJournal использует современные возможности браузера для корректной и безопасной работы.",
      image: "/petjournal/errors/error-406.webp?v=17",
      primary_label: "Обновить браузер",
      secondary_label: "На главную"
    }
  }.freeze

  PUBLIC_FILES = {
    404 => "404.html",
    406 => "406-unsupported-browser.html",
    422 => "422.html",
    500 => "500.html"
  }.freeze

  layout "workspace_new_design"

  def show
    @error_status = requested_status
    @error = ERROR_PAGES.fetch(@error_status, ERROR_PAGES.fetch(500))

    return render_public_error unless user_signed_in?

    @error_primary_path = primary_path
    @error_secondary_path = secondary_path
    @error_primary_external = @error_status == 406

    render :show, status: @error_status
  end

  private

  def requested_status
    status = params[:status].presence&.to_i
    status ||= request.path_info.delete_prefix("/").to_i
    ERROR_PAGES.key?(status) ? status : 500
  end

  def render_public_error
    public_file = PUBLIC_FILES.fetch(@error_status, PUBLIC_FILES.fetch(500))

    render file: Rails.public_path.join(public_file).to_s, layout: false, status: @error_status
  end

  def primary_path
    case @error_status
    when 404, 422
      root_path
    when 406
      "https://browser-update.org/update-browser.html"
    when 500
      original_request_path
    else
      root_path
    end
  end

  def secondary_path
    case @error_status
    when 404, 422
      safe_referer_path
    else
      root_path
    end
  end

  def original_request_path
    path = request.get_header("action_dispatch.original_path").presence
    return root_path unless path&.start_with?("/")

    path
  end

  def safe_referer_path
    referer = request.referer
    return root_path if referer.blank?

    uri = URI.parse(referer)
    return root_path if uri.host.present? && uri.host != request.host

    uri.request_uri.presence || root_path
  rescue URI::InvalidURIError
    root_path
  end
end
