class AddViewsToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :views, :integer, :default => 0
  end
end
