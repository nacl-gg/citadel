class AddDemosTfIdToMatchRound < ActiveRecord::Migration[5.2]
  def change
      add_column :league_match_rounds, :demos_id, :integer
      add_column :league_match_rounds, :gc_demos_id, :integer
  end
end
