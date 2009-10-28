class CreatePreviews < ActiveRecord::Migration
  def self.up
    create_table :previews do |t|
      t.belongs_to :medium
      t.string 'type'
      t.string 'name'
      t.string 'filename'
      t.integer 'height'
      t.integer 'width'
      t.timestamps
    end
  end

  def self.down
    drop_table :previews
  end
end
