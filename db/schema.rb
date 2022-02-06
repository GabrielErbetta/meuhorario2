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

ActiveRecord::Schema.define(version: 2017_12_03_165136) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "areas", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "description"
  end

  create_table "course_class_offers", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.integer "discipline_class_offer_id"
    t.index ["course_id"], name: "index_course_class_offers_on_course_id"
    t.index ["discipline_class_offer_id"], name: "index_course_class_offers_on_discipline_class_offer_id"
  end

  create_table "course_disciplines", id: :serial, force: :cascade do |t|
    t.integer "semester"
    t.string "nature", limit: 3
    t.integer "course_id"
    t.integer "discipline_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_disciplines_on_course_id"
    t.index ["discipline_id"], name: "index_course_disciplines_on_discipline_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "curriculum"
    t.integer "area_id"
    t.index ["area_id"], name: "index_courses_on_area_id"
    t.index ["code"], name: "index_courses_on_code"
  end

  create_table "discipline_class_offers", id: :serial, force: :cascade do |t|
    t.integer "discipline_class_id"
    t.integer "vacancies"
    t.index ["discipline_class_id"], name: "index_discipline_class_offers_on_discipline_class_id"
  end

  create_table "discipline_classes", id: :serial, force: :cascade do |t|
    t.integer "discipline_id"
    t.string "class_number"
    t.index ["discipline_id"], name: "index_discipline_classes_on_discipline_id"
  end

  create_table "disciplines", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "curriculum"
    t.integer "load"
    t.index ["code"], name: "index_disciplines_on_code"
  end

  create_table "pre_requisites", id: :serial, force: :cascade do |t|
    t.integer "pre_discipline_id"
    t.integer "post_discipline_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_discipline_id"], name: "index_pre_requisites_on_post_discipline_id"
    t.index ["pre_discipline_id"], name: "index_pre_requisites_on_pre_discipline_id"
  end

  create_table "professor_schedules", id: :serial, force: :cascade do |t|
    t.integer "schedule_id"
    t.integer "professor_id"
    t.index ["professor_id"], name: "index_professor_schedules_on_professor_id"
    t.index ["schedule_id"], name: "index_professor_schedules_on_schedule_id"
  end

  create_table "professors", id: :serial, force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_professors_on_name"
  end

  create_table "schedules", id: :serial, force: :cascade do |t|
    t.integer "day"
    t.integer "start_hour"
    t.integer "start_minute"
    t.integer "discipline_class_id"
    t.integer "end_hour"
    t.integer "end_minute"
    t.integer "first_class_number"
    t.integer "class_count"
    t.index ["discipline_class_id"], name: "index_schedules_on_discipline_class_id"
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
