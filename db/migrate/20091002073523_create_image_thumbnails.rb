class CreateImageThumbnails < ActiveRecord::Migration
  def self.up
    create_table :image_thumbnails do |t|
      t.integer :size
      t.string  :content_type
      t.string  :filename
      t.integer :height
      t.integer :width
      t.integer :parent_id
      t.string  :thumbnail
      t.timestamps
    end
  end

  def self.down
    drop_table :image_thumbnails
  end
end
