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

ActiveRecord::Schema.define(version: 20200128111859) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dishes", force: :cascade do |t|
    t.string   "name"
    t.integer  "price_cents",       default: 0
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_dishes_count", default: 0
    t.index ["order_id"], name: "index_dishes_on_order_id", using: :btree
  end

  create_table "invitations", force: :cascade do |t|
    t.integer  "company_id"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "authorized", default: false
    t.index ["company_id"], name: "index_invitations_on_company_id", using: :btree
  end

  create_table "orders", force: :cascade do |t|
    t.date     "date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dishes_count",   default: 0
    t.string   "from"
    t.integer  "status",         default: 0
    t.integer  "shipping_cents", default: 0
    t.integer  "company_id"
    t.index ["company_id"], name: "index_orders_on_company_id", using: :btree
    t.index ["user_id"], name: "index_orders_on_user_id", using: :btree
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "payer_id"
    t.integer  "balance_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["payer_id"], name: "index_payments_on_payer_id", using: :btree
    t.index ["user_id"], name: "index_payments_on_user_id", using: :btree
  end

  create_table "transfers", force: :cascade do |t|
    t.integer  "from_id"
    t.integer  "to_id"
    t.integer  "amount_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",       default: 0
    t.index ["from_id"], name: "index_transfers_on_from_id", using: :btree
    t.index ["to_id"], name: "index_transfers_on_to_id", using: :btree
  end

  create_table "user_balances", force: :cascade do |t|
    t.integer  "balance_cents"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payer_id"
    t.index ["payer_id"], name: "index_user_balances_on_payer_id", using: :btree
    t.index ["user_id"], name: "index_user_balances_on_user_id", using: :btree
  end

  create_table "user_dishes", force: :cascade do |t|
    t.integer "user_id"
    t.integer "dish_id"
    t.index ["dish_id"], name: "index_user_dishes_on_dish_id", using: :btree
    t.index ["user_id"], name: "index_user_dishes_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",               default: "",    null: false
    t.string   "encrypted_password",  default: "",    null: false
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.boolean  "admin",               default: false
    t.boolean  "subtract_from_self",  default: false
    t.string   "account_number"
    t.integer  "company_id"
    t.boolean  "company_admin",       default: false
    t.boolean  "active",              default: true
    t.string   "slack_id"
    t.index ["company_id"], name: "index_users_on_company_id", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

  add_foreign_key "invitations", "companies"
  add_foreign_key "orders", "companies"
  add_foreign_key "payments", "users"
  add_foreign_key "payments", "users", column: "payer_id"
end
