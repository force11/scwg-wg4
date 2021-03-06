# frozen_string_literal = true

class TranscriptFromVTT < Nanoc::Filter
  include Nanoc::Helpers::HTMLEscape

  VoiceSpan = Struct.new(:voice, :text, :start, :classes)

  V_SPAN_REGEXP = /(?:<(\d+:\d{2}(?::\d{2})?\.\d{3})>)?<v((?:\.[\w-]+)*) (.+?)>(.*?)(?:<\/v>|\z)/
  C_SPAN_REGEXP = /<c((?:\.[\w-]+)*)>(.*?)<\/c>/
  IBU_SPAN_REGEXP = /<([ibu])((?:\.[\w-]+)*)>(.*?)<\/\1>/
  LANG_SPAN_REGEXP = /<lang((?:\.[\w-]+)*) ([\w-]+)>(.*?)<\/lang>/

  identifier :transcript_from_vtt

  requires 'nokogiri', 'webvtt', 'active_support/core_ext/string/indent'

  # Transform a WebVTT file into a transcript, as either Markdown or HTML.
  #
  # This filter has not been designed to accept any generic WebVTT, but to take
  # the output from the `generate-vtt` command at the root of this project.
  #
  # @param [String] content The content to filter
  #
  # @option params [Symbol] :to The type of output desired; can be `:html` or
  # `:markdown`.
  #
  # @return [String] The filtered content
  def run(content, params = {})
    webvtt = WebVTT.from_blob(content)

    # Filter
    case params[:to]
    when :markdown, :md
      vtt_to_markdown(webvtt)
    when :html
      vtt_to_html(webvtt)
    else
      raise 'The transcript_from_vtt filter needs to know the type of output ' \
        'desired. Pass a :output to the filter call (:html for HTML, ' \
        ':markdown or :md for Markdown).'
    end
  end

  protected

  def vtt_to_markdown(webvtt)
    webvtt.cues
      .flat_map { |cue| voice_spans_from(cue) }
      .chunk { |s| s.voice }
      .map do |voice, v_spans|
        statement = ::Nokogiri::HTML.fragment(v_spans.map(&:text).join(' ')).text
        "#{voice}\n:#{statement.indent(3)}\n\n"
      end.join
  end

  def vtt_to_html(webvtt)
    fragment = Nokogiri::HTML::DocumentFragment.parse ''

    Nokogiri::HTML::Builder.with(fragment) do |html|
      html.section(id: 'cues', class: 'transcript') {
        webvtt.cues
          .flat_map { |cue| voice_spans_from(cue) }
          .chunk { |f| f.voice }
          .each_with_index do |(voice, v_spans), v_idx|
            html.dl(:"data-video-time" => v_spans.first.start) {
              html.dt voice
              v_spans.slice_when { |_, j| j.classes['newthought'] }.each_with_index do |t_spans, t_idx|
                html.dd(id: "statement_#{v_idx}_#{t_idx}", title: voice) {
                  html << t_spans.map { |f| html_tag('span', f.text, class: f.classes) }.join(' ')
                }
              end
            }
          end
      }
    end

    fragment.to_html
  end

  def voice_spans_from(cue)
    cue.text.scan(V_SPAN_REGEXP).map do |v_span|
      timestamp = v_span[0] ? WebVTT::Timestamp.new(v_span[0]) : cue.start
      classes = cue.identifier ? v_span[1] << cue.identifier.dup.prepend('.') : v_span[1]
      voice = v_span[2]
      text = v_span[3]
      VoiceSpan.new(voice, text, timestamp.to_f.round(2, half: :down), classes)
    end
  end

  # Assumes that none of the text is evil markup
  def html_tag(tag_name, text, attributes = {})
    t = text.dup.gsub(C_SPAN_REGEXP) { html_tag('span', $2, class: $1) }
    t.gsub!(IBU_SPAN_REGEXP) { html_tag($1, $3, class: $2) }
    t.gsub!(LANG_SPAN_REGEXP) { html_tag('span', $3, class: $1, lang: $2) }

    attributes.delete_if { |_, v| !v || v.empty? }
    attributes[:class] &&= attributes[:class].scan(/[\.\s]([\w-]+)/).join(' ')
    attributes = attributes.map { |k, v| %(#{k}="#{h(v)}") }.join(' ')

    "<#{tag_name} #{attributes}>#{t}</#{tag_name}>"
  end
end
