class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :digitalid
      t.string :title
      t.string :date

      t.timestamps
    end
  end
end
