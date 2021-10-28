class CreateIndex < ActiveRecord::Migration[4.2]
  def up
    add_index("images", "digitalid", { :name => "digitalid_index", :unique => true })
  end

  def down
    remove_index("images", :name => "digitalid_index")
  end
end
