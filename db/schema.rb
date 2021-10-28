# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2012_04_19_210935) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "animations", id: :serial, force: :cascade do |t|
    t.string "creator"
    t.string "digitalid"
    t.integer "width"
    t.integer "height"
    t.integer "x1"
    t.integer "y1"
    t.integer "x2"
    t.integer "y2"
    t.integer "delay"
    t.string "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "mode"
    t.integer "views", default: 0
    t.text "metadata"
    t.string "rotation"
    t.integer "external_id", default: 0
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.string "digitalid"
    t.text "title"
    t.string "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "converted", default: 0
    t.index ["digitalid"], name: "digitalid_index", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username"
    t.string "crypted_password"
    t.string "password_salt"
    t.string "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
