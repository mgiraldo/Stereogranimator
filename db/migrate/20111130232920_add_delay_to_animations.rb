class AddDelayToAnimations < ActiveRecord::Migration
  def change
    add_column :animations, :delay, :integer
  end
end
