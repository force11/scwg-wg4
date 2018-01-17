# frozen_string_literal = true

class WebVTT2HTML < Nanoc::Filter
  identifier :vtt2html

  requires 'nokogiri', 'webvtt'

  def run(content, params = {})
    webvtt = WebVTT.from_blob(content)

    builder = ::Nokogiri::HTML::Builder.new do |html|
      html.section(id: 'cues') {
        webvtt.cues.each do |cue|
          html.div(id: cue.identifier) {
            html.text cue.text
          }
        end
      }
    end

    builder.to_html
  end
end
