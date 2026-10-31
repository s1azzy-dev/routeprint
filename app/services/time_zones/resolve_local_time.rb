module TimeZones
  # Resolves airport-local civil components without an implicit timezone conversion.
  class ResolveLocalTime
    def self.call(date:, time:, zone:)
      evidence = { time_zone: zone, local_at: nil, at: nil, offset_seconds: nil }
      return evidence.merge(resolution: date ? "date_only" : "not_provided") if time.blank?

      hour, minute = time.split(":").map(&:to_i)
      local = Time.utc(date.year, date.month, date.day, hour, minute)
      evidence = evidence.merge(local_at: local)
      return evidence.merge(resolution: "missing_zone") if zone.blank?

      timezone = TZInfo::Timezone.get(zone)
      period = timezone.period_for_local(local)
      evidence.merge(resolution: "resolved", at: local - period.observed_utc_offset,
        offset_seconds: period.observed_utc_offset)
    rescue TZInfo::AmbiguousTime
      evidence.merge(resolution: "ambiguous")
    rescue TZInfo::PeriodNotFound
      evidence.merge(resolution: "nonexistent")
    rescue TZInfo::InvalidTimezoneIdentifier
      evidence.merge(resolution: "missing_zone")
    end
  end
end
