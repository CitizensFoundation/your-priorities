class RemoveIsVotesSubscribed < ActiveRecord::Migration
  def up
    remove_column :unsubscribes, :is_votes_subscribed
  end

  def down
  end
end
