# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_05_180415) do
  create_table "followings", id: false, force: :cascade do |t|
    t.integer "follower_id", null: false
    t.integer "following_id", null: false
    t.index ["follower_id", "following_id"], name: "index_followings_on_follower_id_and_following_id", unique: true
    t.index ["following_id", "follower_id"], name: "index_followings_on_following_id_and_follower_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
  end

  add_foreign_key "followings", "users", column: "follower_id"
  add_foreign_key "followings", "users", column: "following_id"
end
