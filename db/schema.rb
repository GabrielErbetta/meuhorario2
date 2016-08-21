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

ActiveRecord::Schema.define(version: 20160820170857) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "course_disciplines", force: :cascade do |t|
    t.integer  "semester"
    t.string   "nature",        limit: 3
    t.integer  "course_id"
    t.integer  "discipline_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["course_id"], name: "index_course_disciplines_on_course_id", using: :btree
    t.index ["discipline_id"], name: "index_course_disciplines_on_discipline_id", using: :btree
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "curriculum"
    t.index ["code"], name: "index_courses_on_code", using: :btree
  end

  create_table "disciplines", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.string   "requisites"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_disciplines_on_code", using: :btree
  end

  create_table "pre_requisites", force: :cascade do |t|
    t.integer  "course_discipline_id"
    t.integer  "discipline_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["course_discipline_id"], name: "index_pre_requisites_on_course_discipline_id", using: :btree
    t.index ["discipline_id"], name: "index_pre_requisites_on_discipline_id", using: :btree
  end

  add_foreign_key "course_disciplines", "courses"
  add_foreign_key "course_disciplines", "disciplines"
  add_foreign_key "pre_requisites", "course_disciplines"
  add_foreign_key "pre_requisites", "disciplines"
end
