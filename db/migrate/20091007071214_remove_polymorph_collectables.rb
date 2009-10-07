class RemovePolymorphCollectables < ActiveRecord::Migration
  def self.up
    rename_column :media_set_memberships, :collectable_id, :medium_id
    remove_column :media_set_memberships, :collectable_type
  end

  def self.down
    add_column :media_set_memberships, :collectable_type, :string
    rename_column :media_set_memberships, :medium_id, :collectable_id
  end
end
