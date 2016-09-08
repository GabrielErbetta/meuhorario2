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

ActiveRecord::Schema.define(version: 20160907144414) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "course_class_offers", force: :cascade do |t|
    t.integer "course_id"
    t.integer "discipline_class_offer_id"
    t.index ["course_id"], name: "index_course_class_offers_on_course_id", using: :btree
    t.index ["discipline_class_offer_id"], name: "index_course_class_offers_on_discipline_class_offer_id", using: :btree
  end

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
    t.integer  "area"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "curriculum"
    t.index ["code"], name: "index_courses_on_code", using: :btree
  end

  create_table "discipline_class_offers", force: :cascade do |t|
    t.integer "discipline_class_id"
    t.integer "vacancies"
    t.index ["discipline_class_id"], name: "index_discipline_class_offers_on_discipline_class_id", using: :btree
  end

  create_table "discipline_classes", force: :cascade do |t|
    t.integer "discipline_id"
    t.string  "class_number"
    t.index ["discipline_id"], name: "index_discipline_classes_on_discipline_id", using: :btree
  end

  create_table "disciplines", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_disciplines_on_code", using: :btree
  end

  create_table "pre_requisites", force: :cascade do |t|
    t.integer  "pre_discipline_id"
    t.integer  "post_discipline_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["post_discipline_id"], name: "index_pre_requisites_on_post_discipline_id", using: :btree
    t.index ["pre_discipline_id"], name: "index_pre_requisites_on_pre_discipline_id", using: :btree
  end

  create_table "professor_schedules", force: :cascade do |t|
    t.integer "schedule_id"
    t.integer "professor_id"
    t.index ["professor_id"], name: "index_professor_schedules_on_professor_id", using: :btree
    t.index ["schedule_id"], name: "index_professor_schedules_on_schedule_id", using: :btree
  end

  create_table "professors", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_professors_on_name", using: :btree
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "day"
    t.integer "hour"
    t.integer "minute"
    t.integer "discipline_class_id"
    t.index ["discipline_class_id"], name: "index_schedules_on_discipline_class_id", using: :btree
  end

  add_foreign_key "course_class_offers", "courses"
  add_foreign_key "course_class_offers", "discipline_class_offers"
  add_foreign_key "course_disciplines", "courses"
  add_foreign_key "course_disciplines", "disciplines"
  add_foreign_key "discipline_class_offers", "discipline_classes"
  add_foreign_key "discipline_classes", "disciplines"
  add_foreign_key "pre_requisites", "course_disciplines", column: "post_discipline_id"
  add_foreign_key "pre_requisites", "course_disciplines", column: "pre_discipline_id"
  add_foreign_key "professor_schedules", "professors"
  add_foreign_key "professor_schedules", "schedules"
  add_foreign_key "schedules", "discipline_classes"
end
