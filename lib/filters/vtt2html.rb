# frozen_string_literal = true

class WebVTT2HTML < Nanoc::Filter
  include Nanoc::Helpers::HTMLEscape

  VoiceSpan = Struct.new(:speaker, :text, :start, :classes) unless defined? VoiceSpan

  identifier :vtt2html

  requires 'nokogiri', 'webvtt'

  def run(content, params = {})
    webvtt = WebVTT.from_blob(content)

    fragment = Nokogiri::HTML::DocumentFragment.parse ''

    Nokogiri::HTML::Builder.with(fragment) do |html|
      html.section(id: 'cues', class: 'transcript') {
        webvtt.cues
          .flat_map { |cue| voice_spans_from(cue) }
          .chunk { |f| f.speaker }
          .each_with_index do |(speaker, v_spans), idx|
            html.dl(id: "statement_#{idx}", :"data-video-time" => v_spans.first.start) {
              html.dt speaker
              html.dd(title: speaker) {
                html << v_spans.map { |f| html_tag('span', f.text, f.classes) }.join(' ')
              }
            }
          end
      }
    end

    fragment.to_html
  end

  def voice_spans_from(cue)
    cue.text
      .scan(/<v((?:\.[\w-]+)*) (.+?)>(?:<(\d{2}:\d{2}:\d{2}\.\d{3})>)?(.*?)(?:<\/v>|\z)/)
      .map do |v_span|
        classes = cue.identifier ? v_span[0] << cue.identifier.dup.prepend('.') : v_span[0]
        speaker = v_span[1]
        timestamp = v_span[2] ? WebVTT::Timestamp.new(v_span[2]) : cue.start
        text = v_span[3]
        VoiceSpan.new(speaker, text, timestamp.to_f.round(2, half: :down), classes)
      end
  end

  # Assumes that none of the text is evil markup
  def html_tag(tag_name, cue_text, cue_classes = '', lang = '')
    text = cue_text.dup.gsub(/<c((?:\.[\w-]+)*)>(.*?)<\/c>/) { html_tag('span', $2, $1) }
    text.gsub!(/<([ibu])((?:\.[\w-]+)*)>(.*?)<\/\1>/) { html_tag($1, $3, $2) }
    text.gsub!(/<lang((?:\.[\w-]+)*) ([\w-]+)>(.*?)<\/lang>/) { html_tag('span', $3, $1, $2) }

    attributes = {}
    attributes[:class] = cue_classes.scan(/\.([\w-]+)/).join(' ') unless cue_classes.empty?
    attributes[:lang] = lang unless lang.empty?
    attributes = attributes.map { |key, value| %(#{key}="#{h(value)}") }.join(' ')

    "<#{tag_name} #{attributes}>#{text}</#{tag_name}>"
  end
end
