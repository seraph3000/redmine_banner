# db/migrate/008_add_popup_to_banners.rb
class AddPopupToBanners < ActiveRecord::Migration[4.2]
  def up
    add_column :banners, :popup_enabled, :boolean, default: false, null: false
    add_column :banners, :popup_content, :text
  end

  def down
    remove_column :banners, :popup_content
    remove_column :banners, :popup_enabled
  end
end