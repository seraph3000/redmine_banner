# frozen_string_literal: true

class BannerController < ApplicationController
  #
  # NOTE: Authorized user can turn off banner while their in session. (Changed from version 0.0.9)
  #       If Administrator hope to disable site wide banner, please go to settings page and uncheck
  #       eabned checkbox.
  before_action :require_login, only: %i[off preview]
  before_action :require_banner_preview_access, only: [:preview]
  before_action :find_user, :find_project, :authorize, except: %i[preview off]
  before_action :authorize_manage_banner, only: [:project_banner_off]
  before_action :set_roles_for_banner, only: [:show]

  def preview
    @text = params.dig(:setting, :banner_description)
    render partial: 'common/preview'
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
    role_id = params[:role_id].presence
    @banner = Banner.for_edit(@project, role_id)
    @banner.enabled = false
    @banner.save
    render action: '_project_banner_off', layout: false
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

    # デフォルト( role_id=nil ) のときだけ force_display を反映
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
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_roles_for_banner
    @roles_for_banner = Role.joins(:members)
                            .where(members: { project_id: @project.id })
                            .distinct
                            .order(:position)
  end

  def require_banner_preview_access
    return if User.current.admin? || GlobalBanner.banner_admin?(User.current)

    if params[:project_id].present?
      project = Project.find_by(id: params[:project_id])
      return if project && User.current.allowed_to?(:manage_banner, project)
    end

    render_403
  end

  def authorize_manage_banner
    return if User.current.allowed_to?(:manage_banner, @project)

    render_403
  end

  def banner_params
    params.require(:setting).permit('banner_description', 'style', 'start_date', 'end_date', 'enabled', 'use_timer', 'display_part', 'role_id')
  end
end
