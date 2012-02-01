class AddRotationToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :rotation, :string
  end
end
