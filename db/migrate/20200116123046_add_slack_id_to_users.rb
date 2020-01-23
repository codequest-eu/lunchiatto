class AddSlackIdToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :slack_id, :string, default: nil
  end
end
