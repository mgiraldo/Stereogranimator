class CreateAnimations < ActiveRecord::Migration
  def change
    create_table :animations do |t|
      t.string :creator
      t.string :digitalid
      t.integer :width
      t.integer :height
      t.integer :x1
      t.integer :y1
      t.integer :x2
      t.integer :y2
      t.integer :delay
      t.string :filename

      t.timestamps
    end
  end
end
