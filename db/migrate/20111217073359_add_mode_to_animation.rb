class AddModeToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :mode, :string
  end
end
