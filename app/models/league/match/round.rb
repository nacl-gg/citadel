require 'json'
require 'net/http'
require 'steam_id'
require 'validators/reduce_errors_validator'

class League
  class Match
    class Round < ApplicationRecord
      default_scope { order(:id) }

      belongs_to :match, class_name: 'Match'
      belongs_to :map

      belongs_to :winner, class_name: 'League::Roster', optional: true
      belongs_to :loser,  class_name: 'League::Roster', optional: true

      delegate :division, :league, :home_team, :home_team_id, :away_team, :away_team_id, to: :match, allow_nil: true

      validates :home_team_score, presence: true, numericality: { greater_than_or_equal_to: 0 }, reduce_errors: true
      validates :away_team_score, presence: true, numericality: { greater_than_or_equal_to: 0 }, reduce_errors: true
      validates :has_outcome, inclusion: { in: [true, false] }

      validate :validate_scores

      before_save :update_cache

      def draw?
        home_team_score == away_team_score
      end

      def home_team_won?
        home_team_score > away_team_score
      end

      def away_team_won?
        away_team_score > home_team_score
      end

      def reset_cache!
        update_cache
        save!
      end

      def calculate_winner_id
        if home_team_won?
          match.home_team_id
        elsif away_team_won?
          match.away_team_id
        end
      end

      def update_cache
        self.score_difference = home_team_score - away_team_score

        update_wl_cache
      end

      def logs?
        logs_id != nil
      end

      def fetch_logs
        resp = Net::HTTP.start('logs.tf', 443, use_ssl: true) do |http|
          http.get URI.parse("https://logs.tf/json/#{logs_id}")
        end
        json = JSON.parse(resp.body)
        (json['players'] || []).each do |p|
          p[0] = p[0][1..-2] if p[0].starts_with? '['
          user = User.find_by(steam_id: SteamId.to_64(p[0]))
          p[1]['name'] = user ? user.name : 'UNREGISTERED'
        end
        json
      end

      private

      def update_wl_cache
        if home_team_won? && has_outcome?
          self.winner_id = match.home_team_id
          self.loser_id  = match.away_team_id
        elsif away_team_won? && has_outcome?
          self.winner_id = match.away_team_id
          self.loser_id  = match.home_team_id
        else
          self.winner_id = nil
          self.loser_id  = nil
        end
      end

      def validate_scores
        return if match.blank?

        if has_outcome?
          errors.add(:away_team_score, 'Cannot be tied') if !match.allow_round_draws? && draw?
          errors.add(:logs_id, 'Must reference logs.tf ID') unless logs?
          errors.add(:demos_id, 'Must reference demos.tf ID') if demos_id.nil?
        end
      end
    end
  end
end
