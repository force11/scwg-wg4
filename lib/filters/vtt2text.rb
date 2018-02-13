# frozen_string_literal = true

class WebVTT2Text < Nanoc::Filter
  identifier :vtt2text

  requires 'nokogiri', 'webvtt'

  def run(content, params = {})
    column_width = params.fetch(:width, 72)

    vtt = WebVTT.from_blob(content)
    vtt_text_lines = vtt.cues.map { |cue| cue.text }
    full_text = ::Nokogiri::HTML.fragment(vtt_text_lines.join("\n")).text
    full_text.gsub!(/(\S{#{column_width}})(?=\S)/, '\1 ')
    full_text.gsub!(/(.{1,#{column_width}})(?:\s+|$)/, "\\1\n")
    full_text
  end
end
