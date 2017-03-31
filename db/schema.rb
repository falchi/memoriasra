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

ActiveRecord::Schema.define(:version => 20140106085942) do

  create_table "arcos", :force => true do |t|
    t.boolean "bidi",     :null => false
    t.integer "desde_id", :null => false
    t.integer "hacia_id", :null => false
  end

  add_index "arcos", ["desde_id"], :name => "index_arcos_on_desde_id"
  add_index "arcos", ["hacia_id"], :name => "index_arcos_on_hacia_id"

  create_table "mapas", :force => true do |t|
    t.string   "titulo",     :null => false
    t.float    "indice_cog"
    t.float    "indice_rec"
    t.integer  "persona_id", :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "mapas", ["persona_id"], :name => "index_mapas_on_persona_id"
  add_index "mapas", ["titulo"], :name => "index_mapas_on_titulo"

  create_table "nodos", :force => true do |t|
    t.string  "nombre",  :null => false
    t.string  "texto",   :null => false
    t.integer "x",       :null => false
    t.integer "y",       :null => false
    t.integer "mapa_id", :null => false
  end

  add_index "nodos", ["mapa_id", "nombre"], :name => "index_nodos_on_mapa_id_and_nombre", :unique => true
  add_index "nodos", ["mapa_id"], :name => "index_nodos_on_mapa_id"

  create_table "personas", :force => true do |t|
    t.string   "nombre",      :null => false
    t.string   "rut"
    t.string   "cargo"
    t.integer  "proyecto_id", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "personas", ["nombre"], :name => "index_personas_on_nombre"
  add_index "personas", ["proyecto_id"], :name => "index_personas_on_proyecto_id"
  add_index "personas", ["rut"], :name => "index_personas_on_rut"

  create_table "proyectos", :force => true do |t|
    t.string   "nombre",      :null => false
    t.text     "descripcion", :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "proyectos", ["nombre"], :name => "index_proyectos_on_nombre"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "usuarios", :force => true do |t|
    t.string   "usuario"
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "usuarios", ["email"], :name => "index_usuarios_on_email", :unique => true
  add_index "usuarios", ["reset_password_token"], :name => "index_usuarios_on_reset_password_token", :unique => true

end
