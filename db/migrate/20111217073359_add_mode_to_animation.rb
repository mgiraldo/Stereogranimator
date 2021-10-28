class AddModeToAnimation < ActiveRecord::Migration[4.2]
  def change
    add_column :animations, :mode, :string
  end
end
