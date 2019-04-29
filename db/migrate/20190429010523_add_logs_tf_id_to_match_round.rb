class AddLogsTfIdToMatchRound < ActiveRecord::Migration[5.2]
  def change
      add_column :league_match_rounds, :logs_id, :integer
  end
end
