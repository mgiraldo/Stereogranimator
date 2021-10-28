class ChangeDataTypeForAnimationMetadata < ActiveRecord::Migration[4.2]
  def change
    change_column :animations, :metadata, :text
    change_column :images, :title, :text
  end
end
