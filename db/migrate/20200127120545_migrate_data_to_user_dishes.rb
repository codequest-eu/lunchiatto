class MigrateDataToUserDishes < ActiveRecord::Migration[5.0]
  def up    
    UserDish.create!([
      *Dish.pluck(:user_id, :id).map { |user_id, id| 
        { 
          user_id: user_id,
          dish_id: id 
        }
      }
    ])
  end
  
  def down
    UserDish.pluck(:user_id, :dish_id).each do |user_id, dish_id|
      Dish.find(dish_id).update!(user_id: user_id)
    end
    UserDish.delete_all
  end
end
