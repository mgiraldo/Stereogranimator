class AddBlobToAnimation < ActiveRecord::Migration
  def up
    add_column :animations, :filedata, :binary
  end
  
  def down
    remove_column :animations, :filedata
  end
end
