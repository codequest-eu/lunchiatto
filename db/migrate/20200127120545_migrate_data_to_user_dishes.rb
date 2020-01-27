class MigrateDataToUserDishes < ActiveRecord::Migration[5.0]
  def up
    Dish.all.each do |dish|
      UserDish.new(user_id: dish.user_id, dish_id: dish.id).save
    end
  end
end
