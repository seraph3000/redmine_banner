# db/migrate/007_add_force_display_to_banners.rb
class AddForceDisplayToBanners < ActiveRecord::Migration[4.2]
  def up
    add_column :banners, :force_display, :boolean, default: false, null: false
  end

  def down
    remove_column :banners, :force_display
  end
end
