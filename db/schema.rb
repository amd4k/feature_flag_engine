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

ActiveRecord::Schema[8.0].define(version: 2026_02_09_132253) do
  create_table "feature_overrides", force: :cascade do |t|
    t.integer "feature_id", null: false
    t.string "target_type", null: false
    t.string "target_identifier", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id", "target_type", "target_identifier"], name: "index_feature_overrides_uniqueness", unique: true
    t.index ["feature_id"], name: "index_feature_overrides_on_feature_id"
  end

  create_table "features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "default_enabled", default: false, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_features_on_key", unique: true
  end

  add_foreign_key "feature_overrides", "features"
end
