class AddViewsToAnimation < ActiveRecord::Migration[4.2]
  def change
    add_column :animations, :views, :integer, :default => 0
  end
end
