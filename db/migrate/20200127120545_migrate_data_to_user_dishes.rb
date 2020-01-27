class MigrateDataToUserDishes < ActiveRecord::Migration[5.0]
  def up  
    Dish.all.pluck(:user_id, :id).each do |user_id, id|
      UserDish.create!(user_id: user_id, dish_id: id)
    end
  end
  
  def down
    UserDish.all.pluck(:user_id, :dish_id).each do |user_id, dish_id|
      Dish.find(dish_id).update!(user_id: user_id)
    end
    UserDish.delete_all
  end
end
