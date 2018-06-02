# frozen_string_literal = true

class WebVTT2Markdown < Nanoc::Filter
  identifier :vtt2md

  requires 'nokogiri', 'webvtt', 'active_support/core_ext/string/indent'

  def run(content, params = {})
    webvtt = WebVTT.from_blob(content)

    webvtt.cues
      .flat_map { |cue| cue.text.scan(/<v (.+?)>(?:<\d{2}:\d{2}:\d{2}\.\d{3}>)?(.+?)(?:<\/v>|\z)/) }
      .chunk { |cue| cue.first }
      .map do |voice, cues|
        statement = ::Nokogiri::HTML.fragment(cues.map(&:last).join(' ')).text
        "#{voice}\n:#{statement.indent(3)}\n\n"
      end.join
  end
end
