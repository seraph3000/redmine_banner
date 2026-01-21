# frozen_string_literal: true

module BannerHelper
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

end
