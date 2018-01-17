# frozen_string_literal: true

usage 'generate-vtt [options] json recognition file'
aliases :generate_vtt, :vtt
summary 'generate a caption file from an audio recognition'
description 'Converts a IBM Watson json audio recognition file to a WebVTT caption file'
flag nil, :force, 'force creation of a caption file'

class GenerateVTT < ::Nanoc::CLI::CommandRunner

  Utterance = Struct.new(:word, :start_time, :end_time, :speaker) unless defined? Utterance

  class VTTCue
    attr_reader :identifier, :start_time, :end_time, :speaker, :text

    def initialize(identifier, utterances)
      @identifier = identifier
      @start_time = WebVTT::Timestamp.new(utterances.first.start_time)
      @end_time = WebVTT::Timestamp.new(utterances.last.end_time)
      @speaker = utterances.first.speaker
      @text = utterances.map { |u| u.word }.join(' ')
    end

    def to_webvtt
      cue = String.new
      cue << "\ns-#{identifier}\n"
      cue << "#{start_time} --> #{end_time}\n"
      cue << "<v %SPEAKER_#{speaker}>#{text}\n"
      cue
    end

    alias to_s to_webvtt
  end

  def run
    require 'yajl'
    require 'webvtt'

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    recognition_path = arguments[0]

    # Check for file existence and force flag
    meeting_dir, recognition_name = File.split(recognition_path)
    output = File.join(meeting_dir, File.basename(recognition_name, '.*') + '.vtt')
    if File.exist?(output) && !options[:force]
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The transcript was not created because '#{output}' already exists. " \
        'Re-run the command using --force to create the transcript anyway.',
      )
    end

    recognition_file = File.open(recognition_path)
    parser = Yajl::Parser.new(symbolize_keys: true)
    recognition = parser.parse(recognition_file)

    utterance_map = {}

    results = recognition[:results]
    results.each do |result|
      next unless result[:final]
      alternative = result[:alternatives].first
      alternative[:timestamps].each do |timestamp|
        start_time = timestamp[1]
        utterance_map[start_time] = Utterance.new(*timestamp)
      end
    end

    speaker_labels = recognition[:speaker_labels]
    speaker_labels.each do |speaker_label|
      start_time = speaker_label[:from]
      utterance_map[start_time]&.speaker = speaker_label[:speaker]
    end

    cues = utterance_map.values
      .chunk_while { |b, a| b.speaker == a.speaker }
      .map.with_index(1) { |u, i| VTTCue.new(i, u) }

    meeting_date = recognition_path[/([0-9]{4}-[0-9]{2}-[0-9]{2})/]
    content = <<~EOS
      WEBVTT - SCWG WG4 Telecon (#{meeting_date})
      lang: en

      NOTE This file was generated for the FORCE11 Scholarly Commons Working
      Group 4 through a semi-automatic process. It now represents the
      authoritative transcript of this telecon, and should be edited for
      correction and clarification. Other representations of the meeting will
      be generated from this document. For further information about the WebVTT
      syntax and data model, visit: https://w3c.github.io/webvtt/
    EOS

    content = content + cues.map(&:to_webvtt).compact.join
    File.write(output, content, mode: 'w')

    $stderr.puts "Wrote diarized transcript to '#{output}'"
  end
end

runner GenerateVTT
