# db/migrate/006_add_role_to_banners.rb
class AddRoleToBanners < ActiveRecord::Migration[4.2]
  def up
    add_column :banners, :role_id, :integer
    add_index  :banners, [:project_id, :role_id]
  end

  def down
    remove_index  :banners, column: [:project_id, :role_id]
    remove_column :banners, :role_id
  end
end
