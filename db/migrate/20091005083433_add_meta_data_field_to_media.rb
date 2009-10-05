class AddMetaDataFieldToMedia < ActiveRecord::Migration
  def self.up
    add_column :media, :meta_data, :text
  end

  def self.down
    remove_column :media, :meta_data
  end
end
