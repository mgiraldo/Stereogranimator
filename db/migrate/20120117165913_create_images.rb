class CreateImages < ActiveRecord::Migration[4.2]
  def change
    create_table :images do |t|
      t.string :digitalid
      t.string :title
      t.string :date

      t.timestamps
    end
  end
end
