class PopulateUserDishesCount < ActiveRecord::Migration[5.0]
  def up
    Dish.all.each do |dish|
      Dish.reset_counters(dish.id, :user_dishes)
    end
  end
end
