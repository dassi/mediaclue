class DestroyOldThumbnails < ActiveRecord::Migration
  def self.up

    begin
      Image.destroy_all('parent_id IS NOT NULL')
      remove_column :media, :thumbnail
      remove_column :media, :parent_id
    rescue
      # Ignorieren falls schon entfernt
    end

  end

  def self.down
    add_column :media, :parent_id, :integer
    add_column :media, :thumbnail, :string
  end
end
