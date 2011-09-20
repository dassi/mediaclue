class AddEnableNotificationsToSearchQueries < ActiveRecord::Migration
  def self.up
    add_column :search_queries, :notifications_enabled, :boolean, :default => false
  end

  def self.down
    remove_column :search_queries, :notifications_enabled
  end
end
