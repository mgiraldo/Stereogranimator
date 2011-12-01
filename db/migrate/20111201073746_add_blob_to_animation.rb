class AddBlobToAnimation < ActiveRecord::Migration
  def change
    add_column :animations, :filedata, :binary
  end
end
