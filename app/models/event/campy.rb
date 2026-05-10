#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module Event::Campy
  extend ActiveSupport::Concern

  ABROAD_CANTON = "zz".freeze

  J_S_KINDS = %w[j_s_child j_s_youth j_s_mixed].freeze

  CANTONS = Cantons.short_name_strings + [ABROAD_CANTON]

  EXPECTED_PARTICIPANT_ATTRS = [
    :expected_participants_wolf_f, :expected_participants_wolf_m,
    :expected_participants_pfadi_f, :expected_participants_pfadi_m,
    :expected_participants_pio_f, :expected_participants_pio_m,
    :expected_participants_rover_f, :expected_participants_rover_m,
    :expected_participants_leitung_f, :expected_participants_leitung_m
  ].freeze

  LEADER_CHECKPOINT_ATTRS = [:lagerreglement_applied,
    :kantonalverband_rules_applied,
    :j_s_rules_applied].freeze

  def self.extended(base)
    base.class_eval(&@_included_block)
  end

  included do # rubocop:todo Metrics/BlockLength
    # EEDS: liste réduite — retirés les attributs spécifiques Suisse / J+S :
    #   abteilungsleitung_id, coach_id, advisor_*_security_id,
    #   canton, j_s_kind, j_s_security_*, paper_application_required,
    #   al_present, al_visiting*, coach_visiting*, coach_confirmed,
    #   local_scout_contact*, EXPECTED_PARTICIPANT_ATTRS, LEADER_CHECKPOINT_ATTRS.
    self.used_attributes += [:leader_id,
      :coordinates, :altitude, :emergency_phone,
      :landlord, :landlord_permission_obtained,
      :camp_submitted]

    # EEDS: seul le rôle Leader reste pertinent (pas de Snow/Mountain/Water Security).
    restricted_role :leader, Event::Camp::Role::Leader

    ### VALIDATIONS

    # EEDS: validations Suisse/J+S retirées (canton, j_s_kind, advisors security,
    # presence required at camp_submitted? pour canton/coach/règlements/etc.).
  end

  def abroad?
    canton == ABROAD_CANTON
  end

  def camp_days
    dates.to_a.sum do |d|
      event_date_day_count(d)
    end
  end

  def duplicate
    super.tap do |event|
      event.al_visiting = false
      event.al_visiting_date = nil
      event.coach_visiting = false
      event.coach_visiting_date = nil
      event.coach_confirmed = false
      event.camp_submitted_at = nil
      event.camp_reminder_sent = false
    end
  end

  def total_expected_participants
    %w[wolf pfadi pio rover].product(%w[f m]).map do |level, gender|
      send(:"expected_participants_#{level}_#{gender}") || 0
    end.inject(&:+)
  end

  def total_expected_leading_participants
    %w[leitung].product(%w[f m]).map do |level, gender|
      send(:"expected_participants_#{level}_#{gender}") || 0
    end.inject(&:+)
  end

  private

  def reset_coach_confirmed_if_changed
    if coach_confirmed? && restricted_role_changes[:coach]
      update_column(:coach_confirmed, false)
    end
    true
  end

  def reset_checkpoint_attrs_if_leader_changed
    if restricted_role_changes[:leader]
      LEADER_CHECKPOINT_ATTRS.each do |a|
        update_column(a, false)
      end
    end
  end

  def event_date_day_count(date)
    return 1 unless date.finish_at
    start_at = date.start_at.to_date
    finish_at = date.finish_at.to_date
    (finish_at - start_at).to_i + 1
  end

  def any_expected_participant_attr
    EXPECTED_PARTICIPANT_ATTRS.find do |a|
      send(a).present?
    end
  end
end
