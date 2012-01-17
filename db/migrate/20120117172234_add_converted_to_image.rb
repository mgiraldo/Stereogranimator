class AddConvertedToImage < ActiveRecord::Migration
  def change
    add_column :images, :converted, :integer, :default => 0
  end
end
