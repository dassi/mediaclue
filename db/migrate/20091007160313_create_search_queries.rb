class CreateSearchQueries < ActiveRecord::Migration
  def self.up
    create_table :search_queries do |t|
      t.string :name

      t.text :ferret_query

      t.boolean :audio_clips, :default => false
      t.boolean :video_clips, :default => false
      t.boolean :documents, :default => false
      t.boolean :images, :default => false
      
      t.boolean :my_media_only, :default => false
      
      t.belongs_to :user
      t.integer :position
      t.timestamps
    end
  end

  def self.down
    drop_table :search_queries
  end
end
