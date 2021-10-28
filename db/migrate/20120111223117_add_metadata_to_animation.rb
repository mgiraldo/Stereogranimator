class AddMetadataToAnimation < ActiveRecord::Migration[4.2]
  def change
    add_column :animations, :metadata, :string
  end
end
