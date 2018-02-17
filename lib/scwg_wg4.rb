# frozen_string_literal: true

require 'active_support/core_ext/array/conversions'
require 'active_support/time'

Date::DATE_FORMATS[:long_ordinal_with_weekday] = lambda do |date|
  day_format = ActiveSupport::Inflector.ordinalize(date.day)
  date.strftime("%A, %B #{day_format}, %Y") # => "April 25th, 2007"
end

include Nanoc::Helpers::Rendering
include Nanoc::Helpers::LinkTo

include LinkTo
include Dates
include Meetings
