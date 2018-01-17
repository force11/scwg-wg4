# frozen_string_literal: true

usage 'import-audio [options] file'
aliases :import_audio, :ia
summary 'converts and import a meeting audio recording'
description 'Converts an audio recording of a meeting into file types and qualities appropriate for the Web'
flag nil, :force, 'force conversion of the audio file'
optional :t, :to, 'import audio up to a certain point in time', default: false
optional :p, :part, 'the (zero-based) index of this part of the meeting', default: 0

class ImportAudio < ::Nanoc::CLI::CommandRunner

  class TeleconRecording
    Metadata = Struct.new(:title, :description, :date, :creation_time, :language, :publisher, :album, :track, :encoded_by, :comment) do
      def to_a
        to_h.map do |k, v|
          metadata_option = k == :language ? 'metadata:s:a:0' : 'metadata'
          [metadata_option, "#{k}=#{v}"]
        end
      end
    end

    Telecon = Struct.new(:date) do 
      def number
        Dir.entries(MEETINGS_DIR).sort.drop(2).find_index(date).next
      end
    end

    attr_reader :telecon, :metadata

    def self.create(audio_file)
      require 'media'

      $stderr.print 'Probing audio file… '
      $stderr.flush
      format = Media.probe(audio_file).format
      creation_time = format.tags.fetch('creation_time', File.mtime(audio_file))
      $stderr.puts 'done'

      # parse meeting date from directories and pull site config info for content dir
      # Check for output file existence and force flag
      zoom_time = audio_file[/([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2})/]
      creation_time = 
        if zoom_time
          Time.strptime(zoom_time, '%Y-%m-%d %k.%M.%S')
        else
          Time.parse(creation_time)
        end

      new(creation_time)
    end

    def initialize(creation_time)
      require 'time'

      @telecon = Telecon.new(creation_time.utc.strftime('%F'))

      title = "FORCE11 SCWG WG4 #{telecon.date} Weekly Telecon"
      description = "Audio recording of the #{telecon.date} meeting " \
                    'of the FORCE11 Scholarly Commons Sub Working Group Four: ' \
                    'Enabling Technologies and Infrastructures'
      date = creation_time.utc.iso8601
      new_creation_time = Time.now.utc.iso8601
      language = 'eng'
      publisher = 'FORCE11'
      album = 'SCWG WG4 Weekly Telecons'
      track = telecon.number
      encoded_by = 'Chris Chapman <chris@pentandra.com>'
      comment = 'For more info see ' \
                'https://force11.org/group/scholarly-commons-working-group/wg4enabling-technologies-and-infrastructures'

      @metadata = Metadata.new(title, description, date, new_creation_time,
                               language, publisher, album, track,
                               encoded_by, comment)
    end
  end

  MEETINGS_DIR = 'items/meetings'

  def run
    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    source = arguments[0]
    until_time = options[:to]
    part = options[:part]

    if !File.exist?(source)
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The audio was not imported because '#{source}' was not found."
      )
    end

    recording = TeleconRecording.create(source)

    output_dir = File.join(MEETINGS_DIR, recording.telecon.date)
    ogg = File.join(output_dir, "audio_#{part}.ogg")
    mp3 = File.join(output_dir, "audio_#{part}.mp3")
    if (File.exist?(ogg) || File.exist?(mp3)) && !options[:force]
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        'The audio file was not imported because at least one of the destination files ' \
        "('#{ogg}' or '#{mp3}') already exists. " \
        'Re-run the command using --force to import the audio file anyway.'
      )
    end

    conversion = Media.convert do
      options y: true

      input source do
        options t: until_time if until_time
      end

      output ogg do
        options [['c:a', 'libopus'], ['b:a', '16k'], ['application', 'voip']] | recording.metadata.to_a
      end

      output mp3 do
        options [['c:a', 'libmp3lame'], ['q:a', 9]] | recording.metadata.to_a
      end
    end

    $stderr.puts "Executing command: #{conversion}" if debug?
    conversion.call { |progress| $stderr.print "\r#{(progress.to_f*100).round}% complete" }
    $stderr.puts
    $stderr.puts "Audio recording imported into '#{output_dir}/' successfully"
  end
end

runner ImportAudio
