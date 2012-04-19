class AddExternalIdToAnimations < ActiveRecord::Migration
  def up
    add_column :animations, :external_id, :integer, :default=>0
  end
  def down
    remove_column :animations, :external_id
  end
end
