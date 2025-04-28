class InitDatabase < ActiveRecord::Migration[8.0]
  def change
    # Users table
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :phone_number
      t.string :address
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true

    # Products table
    create_table :products do |t|
      t.string  :title, null: false
      t.text    :description, null: false
      t.string  :category, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :rating, precision: 3, scale: 2
      t.integer :stock
      t.string  :brand
      t.string  :sku
      t.decimal :weight, precision: 8, scale: 2

      t.json    :tags
      t.json    :dimensions
      t.string  :warranty_information
      t.string  :shipping_information
      t.string  :availability_status
      t.string  :return_policy
      t.integer :minimum_order_quantity

      t.json    :meta
      t.json    :images
      t.json    :reviews

      t.timestamps
    end

    # Addresses table
    create_table :addresses do |t|
      t.string :phone_number
      t.string :address
      t.string :postcode
      t.string :city
      t.string :country

      t.timestamps
    end

    # Chats table
    create_table :chats do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    # Messages table
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :content, null: false
      t.string :sender_type
      t.datetime :sent_at

      t.timestamps
    end

    # Orders table
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.json :products

      t.timestamps
    end
  end
end
