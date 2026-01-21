# frozen_string_literal: true

class Banner < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :role, optional: true

  validates :project_id, presence: true
  # 同じ project × 同じ role は 1 件だけ（role_id が NULL の行も 1 件だけ）
  validates :role_id, uniqueness: { scope: :project_id }, allow_nil: true

  validates :display_part, inclusion: { in: %w[all new_issue overview overview_and_issues] }
  validates :style,        inclusion: { in: %w[info warn alert normal nodata] }

  safe_attributes 'banner_description', 'style', 'start_date', 'end_date',
                  'enabled', 'use_timer', 'display_part', 'role_id', 'force_display'

  # 既存互換：デフォルト（role_id = NULL）のバナーを 1 つ確保
  def self.find_or_create(project_id)
    find_or_create_by!(project_id: project_id, role_id: nil) do |banner|
      banner.enabled      = false
      banner.display_part = 'all'
      banner.style        = 'info'
    end
  end

  # 表示用：project + user から「表示すべきバナー 1 件」を返す
  def self.for(project, user)
    return nil unless project

    scope = where(project_id: project.id)

    # ① まずデフォルト（role_id = nil）の「強制表示」バナーがあるか確認
    default = scope.where(role_id: nil).first
    if default&.force_display? && default.enable_banner?
      return default
    end

    # ② 通常のロール優先ロジック
    roles =
      if user&.logged?
        user.roles_for_project(project)
      else
#        [Role.anonymous]
        []
      end

    # Redmine のロール position を使った優先順位でもよいし、
    # 必要ならここに管理者＞責任者＞リーダー…の手動優先度を載せてもOK
    roles.sort_by(&:position).each do |role|
      banner = scope.where(role_id: role.id).first
      return banner if banner&.enable_banner?
    end

    # ③ 何も無ければ通常のデフォルトにフォールバック
    default = scope.where(role_id: nil).first
    return default if default&.enable_banner?

    nil
  end

  # 編集画面用：指定 role_id のバナー 1 件（なければ new）
  def self.for_edit(project, role_id)
    rid = role_id.presence
    banner = where(project_id: project.id, role_id: rid).first
    return banner if banner

    # 新規レコード用のデフォルト値
    new(
      project:       project,
      role_id:       rid,
      enabled:       false,
      display_part:  'all',
      style:         'info'
    )
  end

  def enable_banner?
    enabled && banner_description.present?
  end
end
