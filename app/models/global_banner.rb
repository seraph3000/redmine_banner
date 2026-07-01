# frozen_string_literal: true

class GlobalBanner < Setting
  # Default
  GLOBAL_BANNER_ADMIN_GROUP = 'GlobalBanner_Admin'

  # Allowed values for enum-like settings. Anything else is coerced to a safe
  # default on save so a template that forgets to escape cannot be abused.
  ALLOWED_TYPES        = %w[info warn alert normal nodata].freeze
  ALLOWED_DISPLAY_FOR  = %w[all authenticated anonymous].freeze
  ALLOWED_DISPLAY_PART = %w[header footer both].freeze

  GLOBAL_BANNER_DEFAULT_SETTING = {
    enable: 'false',
    banner_description: 'exp. Information about upcoming Service Interruption.',
    display_for: 'all',
    display_only_login_page: nil,
    type: 'info',
    display_part: 'both',
    use_timer: 'false',
    start_ymd: nil,
    start_hour: nil,
    start_min: nil,
    end_ymd: nil,
    end_hour: nil,
    end_min: nil,
    related_link: nil,
    banner_admin: nil
  }.freeze

  # Class method
  #
  class << self
    def find_or_default
      super('plugin_redmine_banner')
    end

    def banner_admin?(user)
      return true if user.admin?

      instance = find_or_default
      instance.banner_admin?(user)
    end
  end

  def admin_group
    value[:admin_group] || GLOBAL_BANNER_ADMIN_GROUP
  end

  def banner_admin?(user)
    return true if user.admin?

    admin_group = value['banner_admin'] || GLOBAL_BANNER_ADMIN_GROUP

    banner_admin_group = Group.find_by(lastname: admin_group)
    return false if banner_admin_group.blank?

    banner_admin_group.users.include?(user)
  end

  def use_timer?
    value['use_timer'] == 'true'
  end

  def start_time
    get_time(
      value['start_ymd'],
      value['start_hour'],
      value['start_min']
    )
  end

  def end_time
    get_time(
      value['end_ymd'],
      value['end_hour'],
      value['end_min']
    )
  end

  def get_time(ymd, hour, minute)
    begin
      d = Date.strptime(ymd, '%Y-%m-%d')
    rescue StandardError => e
      logger&.warn("Passed value #{ymd} for Banner has wrong format. #{e.message}")
      d = Date.current
    end
    Time.mktime(d.year, d.month, d.day, hour.to_i, minute.to_i)
  end

  def valid_date_range?
    return true unless use_timer?

    end_time > start_time
  end

  def enable?
    value['enable'] == 'true'
  end

  def disable?
    value['enable'] != 'true'
  end

  def merge_value(new_value)
    current_value = value
    merged = current_value.merge(new_value).stringify_keys
    self.value = sanitize_setting(merged)
  end

  private

  # Whitelist enum values and reject non-HTTP(S) related links before the
  # setting is persisted. Applies to both the web UI and the API.
  def sanitize_setting(setting)
    setting = setting.dup

    if setting.key?('type') && !ALLOWED_TYPES.include?(setting['type'])
      setting['type'] = 'info'
    end

    if setting.key?('display_for') && !ALLOWED_DISPLAY_FOR.include?(setting['display_for'])
      setting['display_for'] = 'all'
    end

    if setting.key?('display_part') && !ALLOWED_DISPLAY_PART.include?(setting['display_part'])
      setting['display_part'] = 'both'
    end

    setting['related_link'] = safe_external_url(setting['related_link']) if setting.key?('related_link')

    setting
  end

  def safe_external_url(url)
    return nil if url.blank?

    uri = URI.parse(url.to_s.strip)
    return uri.to_s if uri.is_a?(URI::HTTP) && uri.host.present?

    nil
  rescue URI::InvalidURIError
    nil
  end
end
