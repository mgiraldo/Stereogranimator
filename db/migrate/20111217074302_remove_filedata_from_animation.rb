class RemoveFiledataFromAnimation < ActiveRecord::Migration
  def up
    remove_column :animations, :filedata
  end

  def down
    add_column :animations, :filedata, :string
  end
end
