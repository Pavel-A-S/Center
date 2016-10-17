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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161017032145) do

  create_table "connections", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "login",       limit: 255
    t.string   "password",    limit: 255
    t.text     "description", limit: 65535
    t.integer  "frequency",   limit: 4
    t.string   "identifier",  limit: 255
    t.integer  "time_out",    limit: 4
    t.boolean  "update_me"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "logs", force: :cascade do |t|
    t.string   "controller_identifier", limit: 255
    t.integer  "connection_id",         limit: 4
    t.integer  "event_id",              limit: 4
    t.string   "event_type",            limit: 255
    t.string   "description",           limit: 255
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "ports", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "port_number",   limit: 4
    t.integer  "port_type",     limit: 4
    t.integer  "location_id",   limit: 4
    t.integer  "connection_id", limit: 4
    t.text     "description",   limit: 65535
    t.integer  "order_index",   limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "records", force: :cascade do |t|
    t.integer  "connection_id",         limit: 4
    t.string   "controller_identifier", limit: 255
    t.integer  "voltage_1",             limit: 4
    t.integer  "voltage_2",             limit: 4
    t.integer  "voltage_3",             limit: 4
    t.integer  "voltage_4",             limit: 4
    t.integer  "voltage_5",             limit: 4
    t.integer  "voltage_6",             limit: 4
    t.integer  "voltage_7",             limit: 4
    t.integer  "voltage_8",             limit: 4
    t.integer  "voltage_9",             limit: 4
    t.integer  "voltage_10",            limit: 4
    t.integer  "voltage_11",            limit: 4
    t.integer  "voltage_12",            limit: 4
    t.integer  "voltage_13",            limit: 4
    t.integer  "voltage_14",            limit: 4
    t.integer  "voltage_15",            limit: 4
    t.integer  "voltage_16",            limit: 4
    t.integer  "state_1",               limit: 4
    t.integer  "state_2",               limit: 4
    t.integer  "state_3",               limit: 4
    t.integer  "state_4",               limit: 4
    t.integer  "state_5",               limit: 4
    t.integer  "state_6",               limit: 4
    t.integer  "state_7",               limit: 4
    t.integer  "state_8",               limit: 4
    t.integer  "state_9",               limit: 4
    t.integer  "state_10",              limit: 4
    t.integer  "state_11",              limit: 4
    t.integer  "state_12",              limit: 4
    t.integer  "state_13",              limit: 4
    t.integer  "state_14",              limit: 4
    t.integer  "state_15",              limit: 4
    t.integer  "state_16",              limit: 4
    t.integer  "output_1",              limit: 4
    t.integer  "output_2",              limit: 4
    t.integer  "output_3",              limit: 4
    t.integer  "output_4",              limit: 4
    t.integer  "output_5",              limit: 4
    t.integer  "output_6",              limit: 4
    t.integer  "output_7",              limit: 4
    t.integer  "profile",               limit: 4
    t.integer  "temp",                  limit: 4
    t.decimal  "power",                               precision: 14, scale: 2
    t.string   "partition_1",           limit: 255
    t.string   "partition_2",           limit: 255
    t.string   "partition_3",           limit: 255
    t.string   "partition_4",           limit: 255
    t.string   "battery_state",         limit: 255
    t.string   "balance",               limit: 255
    t.text     "full_message",          limit: 65535
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.integer  "role",                   limit: 4
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
