class AddDishOwnerToUserDishes < ActiveRecord::Migration[5.0]
  def change
    add_column :user_dishes, :dish_owner, :boolean, default: true
  end
end
