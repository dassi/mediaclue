class AddMediumFields < ActiveRecord::Migration
  def self.up
    add_column :media, :source, :string
  end

  def self.down
    remove_column :media, :source
  end
end
