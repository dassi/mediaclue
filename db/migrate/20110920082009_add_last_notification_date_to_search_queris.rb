class AddLastNotificationDateToSearchQueris < ActiveRecord::Migration
  def self.up
    add_column :search_queries, :last_notification_datetime, :datetime
  end

  def self.down
    remove_column :search_queries, :last_notification_datetime
  end
end
