class CreateUserDishes < ActiveRecord::Migration[5.0]
  def change
    create_table :user_dishes do |t|
      t.belongs_to :user
      t.belongs_to :dish
    end
  end
end
