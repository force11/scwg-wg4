# frozen_string_literal: true

module Meetings
  def meetings
    blk = -> { @items.find_all('/meetings/*/index') }
    if @items.frozen?
      @meetings_items ||= blk.call
    else
      blk.call
    end
  end

  def sorted_meetings
    blk = -> { meetings.sort_by(&:identifier).reverse }
    if @items.frozen?
      @sorted_meeting_items ||= blk.call
    else
      blk.call
    end
  end

  def meeting_date(item)
    date_string = item.identifier.to_s[/[0-9]{4}-[0-9]{2}-[0-9]{2}/]
    Date.parse(date_string)
  end

  def index_for(item)
    @items["/meetings/#{meeting_date(item)}/index"]
  end

  def previous_index_for(item)
    previous_index = sorted_meetings.index(index_for(item))&.succ
    previous_index &&= sorted_meetings.at(previous_index)
  end

  def notes_for(item)
    @items["/meetings/#{meeting_date(item)}/notes"]
  end

  def transcripts_for(item)
    @items.find_all(File.dirname(item.identifier.to_s) + '/audio_*.vtt').sort_by(&:identifier)
  end

  def generate_meeting_index_for(item)
    @items.create(
      '',
      { title: "WG4 Meeting #{meeting_date(item)}", kind: 'meeting-index' },
      "/meetings/#{meeting_date(item)}/index")
  end
end
