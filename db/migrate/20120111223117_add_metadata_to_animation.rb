class AddMetadataToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :metadata, :string
  end
end
