# frozen_string_literal: true

module Dates
  def time_in_zone(time, zone)
    zone_time = time.in_time_zone(zone)
    "#{zone_time.to_s(:time)} #{zone_time.zone}"
  end
end
