class Create < ActiveRecord::Migration
  def change
    create_table(:usuarios) do |t|
      ## Database authenticatable
	  t.string :usuario
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Token authenticatable
      # t.string :authentication_token


      t.timestamps
    end

    add_index :usuarios, :email,                :unique => true
    add_index :usuarios, :reset_password_token, :unique => true

	create_table :proyectos do |t|
		t.string :nombre, :null => false
		t.text :descripcion, :null => false
        
        t.timestamps
	end
    add_index :proyectos, :nombre
	
	create_table :personas do |t|
		t.string :nombre, :null => false
		t.string :rut
		t.string :cargo
		t.references :proyecto, :null => false

		t.timestamps
	end
    add_index :personas, :nombre
    add_index :personas, :rut
    add_index :personas, :proyecto_id

	create_table :mapas do |t|
		t.string :titulo, :null => false
		t.float :indice_cog
		t.float :indice_rec
		t.references :persona, :null => false
        
        t.timestamps
	end
    add_index :mapas, :titulo
    add_index :mapas, :persona_id

    create_table :nodos do |t|
      t.string :nombre, :null => false
      t.string :texto, :null => false
      t.integer :x, :null => false
      t.integer :y, :null => false
      t.references :mapa, :null => false
	  
      #t.timestamps
    end
    add_index :nodos, [:mapa_id, :nombre], :unique => true
    add_index :nodos, :mapa_id

	create_table :arcos do |t|
		t.boolean :bidi, :null => false
		t.references :desde, :class_name => "Nodo", :null => false
		t.references :hacia, :class_name => "Nodo", :null => false
        
        #t.timestamps
	end
    add_index :arcos, :desde_id
    add_index :arcos, :hacia_id
  end
end
