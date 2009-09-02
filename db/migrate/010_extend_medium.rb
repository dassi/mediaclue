class ExtendMedium < ActiveRecord::Migration
  def self.up
    add_column :media, :original_filename, :string
    add_column :media, :is_public, :boolean
  end

  def self.down
    remove_column :media, :original_filename
    remove_column :media, :is_public
  end
end
