class AddBlobToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :filedata, :blob
  end
end
