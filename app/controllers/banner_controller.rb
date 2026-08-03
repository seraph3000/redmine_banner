# frozen_string_literal: true

class BannerController < ApplicationController
  #
  # NOTE: Authorized user can turn off banner while their in session. (Changed from version 0.0.9)
  #       If Administrator hope to disable site wide banner, please go to settings page and uncheck
  #       eabned checkbox.
  before_action :require_login, only: %i[off project_banner_off preview]
  before_action :find_user, :find_project, except: %i[preview off]
  before_action :authorize, except: %i[preview off project_banner_off]
  before_action :authorize_preview, only: [:preview]

  def preview
    text = params[:text].to_s

    popup_enabled = %w[1 true].include?(params[:popup_enabled].to_s)

    @text = view_context.banner_expand_macros(
      view_context.textilizable(text),
      popup_enabled: popup_enabled,
      popup_content: popup_enabled ? '1' : nil,
      popup_preview: true
    ).html_safe
    render partial: 'banner/preview'
  end

  #
  # Turn off (hide) banner while in user's session.
  #
  def off
    session[:pref_banner_off] = Time.now.to_i
    render action: '_off', layout: false
  rescue StandardError => e
    logger&.warn("Message for the log file / When off banner #{e.message}")
    render plain: ''
  end

  def project_banner_off
    store = (session[:pref_project_banner_off] ||= {})
    store[@project.id.to_s] = Time.now.to_i

    if store.size > 20
      session[:pref_project_banner_off] = store.sort_by { |_, v| -v.to_i }.first(20).to_h
    end

    render action: '_project_banner_off', layout: false
  rescue StandardError => e
    logger&.warn("When off project banner #{e.message}")
    render plain: ''
  end

  def show
    @role_id = params[:role_id].presence

    @banner_roles =
      @project.memberships.includes(:roles).flat_map(&:roles).uniq.sort_by(&:position)

    @banner = Banner.for_edit(@project, @role_id)
    render layout: !request.xhr?
  end

  def edit
    return if params[:setting].nil?

    role_id = params[:setting][:role_id].presence
    @banner = Banner.for_edit(@project, role_id)
    @banner.safe_attributes = banner_params
    @banner.role_id = role_id

    if @banner.role_id.nil?
      @banner.force_display = params[:setting][:force_display].present?
    else
      @banner.force_display = false
    end

    if @banner.save
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = @banner.errors.full_messages
    end

    redirect_to action: 'show', project_id: @project, role_id: role_id
  end

  private

  def find_user
    @user = User.current
  end

  def find_project
    @project = Project.find(params[:project_id])
    render_404 unless @project.visible?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_roles_for_banner
    @roles_for_banner = Role.joins(:members)
                            .where(members: { project_id: @project.id })
                            .distinct
                            .order(:position)
  end

  def banner_params
    params.require(:setting).permit('banner_description', 'style', 'start_date', 'end_date', 'enabled', 'use_timer', 'display_part', 'role_id', 'popup_enabled', 'popup_content')
  end

  def authorize_preview
    return if User.current.admin?
    return if GlobalBanner.banner_admin?(User.current)

    allowed = User.current.memberships.any? do |m|
      m.roles.any? { |r| r.allowed_to?(:manage_banner) }
    end
    render_403 unless allowed
  end
end
