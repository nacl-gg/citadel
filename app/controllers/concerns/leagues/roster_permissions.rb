module Leagues
  module RosterPermissions
    extend ActiveSupport::Concern
    include ::LeaguePermissions

    def user_can_sign_up?(league = nil, team = nil)
      league ||= @league
      team ||= @team

      user_signed_in? && league.signuppable? && current_user.can?(:edit, :team) &&
        current_user.can?(:use, :leagues) && (team.nil? || user_can_sign_up_team?(league, team))
    end

    def user_can_edit_roster?(roster = nil)
      roster ||= @roster
      disbanded = roster && roster.disbanded?

      user_can_edit_league?(roster.league) ||
        user_signed_in? && current_user.can?(:edit, roster.team) && !disbanded
    end

    def user_can_disband_roster?(roster = nil)
      roster ||= @roster

      user_can_edit_league?(roster.league) || (
        user_can_edit_roster?(roster) && roster.league.allow_disbanding?)
    end

    def user_can_destroy_roster?(roster = nil)
      roster ||= @roster

      user_can_edit_league?(roster.league) && roster.matches.empty?
    end

    private

    def user_can_sign_up_team?(league, team)
      !team.entered?(league) && current_user.can?(:edit, team)
    end
  end
end
