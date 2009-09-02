class CreateMediaSetMemberships < ActiveRecord::Migration
  def self.up
    create_table :media_set_memberships do |t|
      t.integer :collectable_id
      t.string  :collectable_type
      t.integer :media_set_id
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :media_set_memberships
  end
end
