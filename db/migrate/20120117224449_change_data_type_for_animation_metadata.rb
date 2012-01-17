class ChangeDataTypeForAnimationMetadata < ActiveRecord::Migration
  def change
    change_column :animations, :metadata, :text
    change_column :images, :title, :text
  end
end
