# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120419210935) do

  create_table "animations", :force => true do |t|
    t.string   "creator"
    t.string   "digitalid"
    t.integer  "width"
    t.integer  "height"
    t.integer  "x1"
    t.integer  "y1"
    t.integer  "x2"
    t.integer  "y2"
    t.integer  "delay"
    t.string   "filename"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mode"
    t.integer  "views",       :default => 0
    t.text     "metadata"
    t.string   "rotation"
    t.integer  "external_id", :default => 0
  end

  create_table "images", :force => true do |t|
    t.string   "digitalid"
    t.text     "title"
    t.string   "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "converted",  :default => 0
  end

  add_index "images", ["digitalid"], :name => "digitalid_index", :unique => true

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
