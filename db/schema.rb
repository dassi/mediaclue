# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110920070107) do

  create_table "bj_config", :primary_key => "bj_config_id", :force => true do |t|
    t.text "hostname"
    t.text "key"
    t.text "value"
    t.text "cast"
  end

  create_table "bj_job", :primary_key => "bj_job_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "bj_job_archive", :primary_key => "bj_job_archive_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "media", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "desc"
    t.date     "origin_date"
    t.integer  "size"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "height"
    t.integer  "width"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "original_filename"
    t.string   "source"
    t.text     "meta_data"
    t.integer  "owner_id"
    t.string   "permission_type"
  end

  create_table "media_set_memberships", :force => true do |t|
    t.integer  "medium_id"
    t.integer  "media_set_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media_sets", :force => true do |t|
    t.string   "name"
    t.text     "desc"
    t.string   "state"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sort_path"
    t.integer  "rating",          :default => 0
    t.string   "permission_type", :default => "owner"
  end

  create_table "previews", :force => true do |t|
    t.integer  "medium_id"
    t.string   "type"
    t.string   "name"
    t.string   "filename"
    t.integer  "height"
    t.integer  "width"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_queries", :force => true do |t|
    t.string   "name"
    t.text     "ferret_query"
    t.boolean  "audio_clips",           :default => false
    t.boolean  "video_clips",           :default => false
    t.boolean  "documents",             :default => false
    t.boolean  "images",                :default => false
    t.boolean  "my_media_only",         :default => false
    t.integer  "user_id"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notifications_enabled", :default => false
  end

  create_table "taggings", :force => true do |t|
    t.integer "tag_id",        :null => false
    t.integer "taggable_id",   :null => false
    t.string  "taggable_type", :null => false
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_id_and_taggable_type", :unique => true

  create_table "tags", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "user_group_memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "user_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_group_permissions", :force => true do |t|
    t.integer  "user_group_id"
    t.integer  "object_id"
    t.string   "object_type"
    t.boolean  "read",          :default => false
    t.boolean  "write",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_groups", :force => true do |t|
    t.string  "full_name"
    t.string  "uid"
    t.boolean "can_upload", :default => true
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "full_name"
    t.integer  "last_search_query_id"
  end

end
