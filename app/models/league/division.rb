require 'tournament_driver'

class League
  class Division < ApplicationRecord
    belongs_to :league, inverse_of: :divisions
    has_many :rosters, inverse_of: :division, class_name: 'Roster'
    has_many :matches, through: :rosters, source: :home_team_matches, class_name: 'Match'

    has_many :transfer_requests, through: :rosters, class_name: 'Roster::TransferRequest'

    validates :name, presence: true, length: { in: 1..64 }

    TOURNAMENT_SYSTEMS = [
      :swiss, :round_robin, :single_elimination, :page_playoffs,
    ].freeze

    SWISS_PAIRERS = [
      :dutch
    ].freeze

    # TODO: Replace messy handling here with normal models
    def generate_matches(system, match_options, options = {})
      return unless TOURNAMENT_SYSTEMS.include?(system)

      send("generate_#{system}", match_options, options)
      @driver&.created_matches
    end

    private

    def new_driver(match_options, options = {})
      @driver = ::TournamentDriver.new(self, match_options, options)
    end

    def generate_swiss(match_options, options)
      pairer = options[:pairer].to_sym
      return unless SWISS_PAIRERS.include?(pairer)

      send("generate_swiss_#{pairer}", match_options, options)
    end

    def generate_swiss_dutch(match_options, options)
      options[:pair_options] ||= {}
      min_pair_size = (options[:pair_options][:min_pair_size] || 4).to_i
      pair_options = { min_pair_size: min_pair_size }

      tournament_options = { pairer: Tournament::Swiss::Dutch, pair_options: pair_options }
      Tournament::Swiss.generate new_driver(match_options), tournament_options
    end

    def generate_round_robin(match_options, _)
      Tournament::RoundRobin.generate new_driver(match_options)
    end

    def generate_single_elimination(match_options, options)
      match_options[:has_winner] = true
      driver_options = options.slice(:teams_limit, :starting_round)
      Tournament::SingleElimination.generate new_driver(match_options, driver_options)
    end

    def generate_page_playoffs(match_options, options)
      match_options[:has_winner] = true
      driver_options = options.slice(:starting_round)
      Tournament::SingleElimination.generate new_driver(match_options, driver_options)
    end
  end
end
