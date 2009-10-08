class AddLastSearchQueryToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :last_search_query_id, :integer
  end

  def self.down
    remove_column :users, :last_search_query_id
  end
end
