class AddUserDishesCountToDishes < ActiveRecord::Migration[5.0]
  def change
    add_column :dishes, :user_dishes_count, :integer, default: 0
  end
end
