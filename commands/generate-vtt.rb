# frozen_string_literal: true

usage 'generate-vtt [options] json recognition file'
aliases :generate_vtt, :vtt
summary 'generate a caption file from an audio recognition'
description 'Converts a IBM Watson json audio recognition file to a WebVTT caption file'
flag nil, :force, 'force creation of a caption file'

class GenerateVTT < ::Nanoc::CLI::CommandRunner

  Utterance = Struct.new(:word, :start_time, :end_time, :speaker) unless defined? Utterance

  class VTTCue
    attr_reader :identifier, :start_time, :end_time, :text

    def self.v(speaker, text)
      "<v %SPEAKER_#{speaker}>#{text}</v>"
    end

    def initialize(identifier, utterances)
      @identifier = identifier
      @start_time = WebVTT::Timestamp.new(utterances.first.start_time)
      @end_time = WebVTT::Timestamp.new(utterances.last.end_time)
      @text = utterances
        .chunk { |u| u.speaker }
        .map { |s, utts| self.class.v(s, utts.map { |u| u.word }.join(' ')) }
        .join
    end

    def to_webvtt
      cue = String.new
      cue << "\ncue-#{identifier}"
      cue << "\n#{start_time} --> #{end_time}"
      cue << "\n#{text}\n"
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
    output_file = File.join(meeting_dir, File.basename(recognition_name, '.*') + '.vtt')
    if File.exist?(output_file) && !options[:force]
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The transcript was not created because '#{output_file}' already exists. " \
        'Re-run the command using --force to create the transcript anyway.',
      )
    end

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    recognition_file = File.open(recognition_path)
    parser = Yajl::Parser.new(symbolize_keys: true)
    recognition = parser.parse(recognition_file)

    utterance_map = {}

    speaker_labels = recognition[:speaker_labels].to_enum
    recognition[:results].each do |result|
      next unless result[:final]
      alternative = result[:alternatives].first
      utterances = alternative[:timestamps].map do |u|
        speaker_label = speaker_labels.next
        Utterance.new(*u, speaker_label[:speaker])
      end
      start_time = utterances.first.start_time
      utterance_map[start_time] = utterances
    end

    cues = utterance_map.values
      .map.with_index(1) { |u, i| VTTCue.new(i, u) }

    meeting_date = recognition_path[/([0-9]{4}-[0-9]{2}-[0-9]{2})/]
    header = <<~EOS
      WEBVTT - SCWG WG4 Telecon (#{meeting_date})
      lang: en

      NOTE This file was generated for the FORCE11 Scholarly Commons Working
      Group 4 through a semi-automatic process. It now represents the
      authoritative transcript of this telecon, and should be edited for
      correction, clarification, and diplomacy. Other representations of the
      meeting will be generated from this document.

      NOTE For further information about the WebVTT syntax and data model,
      visit: https://w3c.github.io/webvtt/
    EOS

    content = header + cues.map(&:to_webvtt).compact.join
    write(output_file, content)
  end

  private

  def write(filename, content)
    File.write(filename, content)
    Nanoc::Int::NotificationCenter.post(:file_created, filename)
  end
end

runner GenerateVTT
