# frozen_string_literal: true

module Dates
  def meeting_date(item)
    date_string = item.identifier.to_s[/[0-9]{4}-[0-9]{2}-[0-9]{2}/]
    Date.parse(date_string)
  end
end
