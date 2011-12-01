class AddBlobToAnimation < ActiveRecord::Migration
  def up
    add_column :animations, :filedata, :binary, :limit => 10.megabyte
  end
  
  def down
    remove_column :animations, :filedata
  end
end
