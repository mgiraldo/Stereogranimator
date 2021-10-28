class AddRotationToAnimation < ActiveRecord::Migration[4.2]
  def change
    add_column :animations, :rotation, :string
  end
end
