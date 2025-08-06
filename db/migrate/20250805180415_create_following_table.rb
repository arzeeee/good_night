class CreateFollowingTable < ActiveRecord::Migration[8.0]
  def change
    create_table :followings, id: false do |t|
      t.integer :follower_id, null: false
      t.integer :following_id, null: false
      
      t.index [:follower_id, :following_id], unique: true
      t.index [:following_id, :follower_id]
    end
    
    add_foreign_key :followings, :users, column: :follower_id
    add_foreign_key :followings, :users, column: :following_id
  end
end

