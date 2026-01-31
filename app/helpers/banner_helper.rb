# frozen_string_literal: true

module BannerHelper
  include ApplicationHelper

  def banner_use_svg_icons?
    false
  end

  def banner_style_icon_name(style)
    case style.to_s
    when 'info', '' then 'info-circle'
    when 'warn'     then 'alert-triangle'
    when 'alert'    then 'alert-circle'
    when 'normal'   then 'bell'
    when 'nodata'   then 'circle-dashed'
    else                 'info-circle'
    end
  end

  def banner_style_icon(style)
    return ''.html_safe unless banner_use_svg_icons?

    sprite_icon(
      banner_style_icon_name(style),
      nil,
      icon_only: true,
      css_class: 'banner-icon-svg'
    )
  end

  def banner_action_icon_edit
    return ''.html_safe unless banner_use_svg_icons?
    sprite_icon('edit', nil, icon_only: true, css_class: 'banner-icon-edit-svg')
  end

  def banner_action_icon_off
    return ''.html_safe unless banner_use_svg_icons?
    sprite_icon('x', nil, icon_only: true, css_class: 'banner-icon-off-svg')
  end

  def banner_role_color_class(role)
    return '' unless role

    # 一度だけロール→クラスのマップを作ってキャッシュ
    @banner_role_color_map ||= begin
      # position 昇順（優先度高い順）で givable ロールから上位5件
      ids = Role.givable.order(:position).limit(7).pluck(:id)
      ids.each_with_index.to_h do |id, idx|
        [id, "banner-role-label-#{idx + 1}"] # 1〜7 を割り振り
      end
    end

    @banner_role_color_map[role.id] || ''
  end

  def banner_expand_macros(text)
    return '' if text.blank?

    s = text.to_s.dup

    # タイムゾーンと現在時刻
    zone =
      if User.current.respond_to?(:time_zone) && User.current.time_zone.present?
        User.current.time_zone
      else
        Time.zone || Time
      end
    now = zone.respond_to?(:now) ? zone.now : Time.now

    # --- 引数なしマクロ群 ---
    s.gsub!(/%\{(today|now|env|user_name|user_last_login|user_login_rank_today)\}/) do
      case Regexp.last_match(1)
      when 'today'
        format_date(now.to_date)     # ← ユーザー設定に従う
      when 'now'
        format_time(now)
      when 'env'
        banner_env_label
      when 'user_name'
        banner_user_name
      when 'user_last_login'
        banner_user_last_login
      when 'user_login_rank_today'
        banner_user_login_rank_today
      end
    end

    # --- cdate/chours/cmin/ctime 系 ---
    s.gsub!(/%\{([^}]+)\}/) do
      inner = Regexp.last_match(1).strip

      unless inner =~ /\A(cdate|chours|cmin|ctime)\s*:\s*(.+)\z/
        next "%{#{inner}}"
      end

      kind = Regexp.last_match(1)
      raw  = Regexp.last_match(2).strip

      begin
        deadline =
          if zone.respond_to?(:parse)
            zone.parse(raw)
          else
            require 'time'
            Time.parse(raw)
          end
      rescue StandardError
        deadline = nil
      end

      next "%{#{inner}}" unless deadline

      diff = (deadline - now).to_i

      if diff <= 0
        kind == 'ctime' ? '00:00' : '0'
      else
        total_minutes = diff / 60
        days    = total_minutes / (60 * 24)
        hours   = (total_minutes % (60 * 24)) / 60
        minutes = total_minutes % 60

        case kind
        when 'cdate'  then days.to_s
        when 'chours' then hours.to_s
        when 'cmin'   then minutes.to_s
        when 'ctime'
          total_hours = total_minutes / 60
          format('%02d:%02d', total_hours, minutes)
        end
      end
    end

    s
  end

  def banner_user_login_rank_today
    user = User.current
    return '' unless user && user.logged? && user.last_login_on

    login_time = user.last_login_on
    day = login_time.to_date

    # 同じ日付かつ自分のログイン時刻までにログインしたユーザー数
    count = User.where(last_login_on: day.beginning_of_day..login_time).count
    count.zero? ? '' : count.to_s
  end

  def login_page?
    controller.controller_name == 'account' && controller.action_name == 'login'
  rescue
    false
  end

  def banner_user_last_login
    user = User.current
    return '' if login_page?
    return '' unless user && user.logged? && user.last_login_on

    format_date(user.last_login_on)
  end

  def banner_user_name
    user = User.current
    return '' unless user && user.logged?
    user.name
  end

  def banner_env_label
    env = defined?(Rails) ? Rails.env.to_s : 'unknown'
    case env
    when 'production'  then 'PROD'
    when 'staging'     then 'STG'
    when 'development' then 'DEV'
    else env.upcase
    end
  end

end
