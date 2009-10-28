class RemoveAttachmentFuStuff < ActiveRecord::Migration
  def self.up
    drop_table :image_thumbnails
  end

  def self.down
    create_table "image_thumbnails", :force => true do |t|
      t.integer  "size"
      t.string   "content_type"
      t.string   "filename"
      t.integer  "height"
      t.integer  "width"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
