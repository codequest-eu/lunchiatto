class ChangeDishOwnerDefaultValue < ActiveRecord::Migration[5.0]
  def change
    change_column_default :user_dishes, :dish_owner, from: true, to: false
  end
end
