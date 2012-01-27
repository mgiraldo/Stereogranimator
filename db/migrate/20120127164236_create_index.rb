class CreateIndex < ActiveRecord::Migration
  def up
    add_index("images", "digitalid", { :name => "digitalid_index", :unique => true })
  end

  def down
    remove_index("images", :name => "digitalid_index")
  end
end
