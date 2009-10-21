class AddSortPathToMediaSet < ActiveRecord::Migration
  def self.up
    add_column :media_sets, :sort_path, :string
  end

  def self.down
    remove_column :media_sets, :sort_path
  end
end
