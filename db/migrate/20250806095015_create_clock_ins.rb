class CreateClockIns < ActiveRecord::Migration[8.0]
  def change
    create_table :clock_ins do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :clock_in_time, null: false
      t.datetime :clock_out_time
      t.decimal :duration_seconds, precision: 10, scale: 3
      t.timestamps
    end
  end
end
