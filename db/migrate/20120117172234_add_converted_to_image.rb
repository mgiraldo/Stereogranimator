class AddConvertedToImage < ActiveRecord::Migration[4.2]
  def change
    add_column :images, :converted, :integer, :default => 0
  end
end
