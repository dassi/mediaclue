class CreateMedia < ActiveRecord::Migration
  def self.up
    create_table :media do |t|
      t.string  :type
      t.string  :name
      t.text    :desc
      t.date    :origin_date
      t.string  :type
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
    drop_table :media
  end
end
