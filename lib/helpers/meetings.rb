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
    current_index_item = index_for(item)
    previous_index = current_index_item ? sorted_meetings.index(current_index_item).succ : 0
    previous_index &&= sorted_meetings.at(previous_index)
  end

  def notes_for(item)
    @items["/meetings/#{meeting_date(item)}/notes"]
  end

  def transcripts_for(item)
    pattern = File.join(File.dirname(item.identifier.to_s), 'audio_*.vtt')
    @items.find_all(pattern).sort_by(&:identifier)
  end

  def media_for(item)
    pattern = File.join(File.dirname(item.identifier.to_s), '{audio,video}_*.{ogg,mp3,mp4}')
    @items.find_all(pattern).sort_by(&:identifier)
  end

  def media_groups_for(item)
    media_for(item).group_by { |i| i.identifier.to_s[/_(?<index>\d+)/, 'index'] }
  end

  def mimetype_for(item)
    item.identifier.to_s[/(audio|video)/] + '/' + item.identifier.ext
  end

  def generate_meeting_index_for(item)
    @items.create(
      '',
      { title: "WG4 Meeting #{meeting_date(item)}", kind: 'meeting-index' },
      "/meetings/#{meeting_date(item)}/index")
  end
end
