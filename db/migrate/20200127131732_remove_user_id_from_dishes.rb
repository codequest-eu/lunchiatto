class RemoveUserIdFromDishes < ActiveRecord::Migration[5.0]
  def change
    remove_column :dishes, :user_id, :integer
  end
end
