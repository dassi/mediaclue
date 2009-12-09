class AddRatingToMediaSet < ActiveRecord::Migration
  def self.up
    add_column :media_sets, :rating, :integer, :default => 0
  end

  def self.down
    remove_column :media_sets, :rating
  end
end
