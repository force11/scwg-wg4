# frozen_string_literal = true

usage 'recognize-audio [args] audio_file'
aliases :recognize_audio, :ra
summary 'creates a recognition of an audio file'
description 'Currently uses the IBM Watson Speech to Text service to recognize audio'

class RecognizeAudio < ::Nanoc::CLI::CommandRunner
  Credentials = Struct.new(:url, :username, :password)

  ACCEPTED_FORMATS = %w(flac mp3 mpeg ogg wav webm) unless defined? ACCEPTED_FORMATS

  def run
    require 'time'
    require 'json'
    require 'net/http'
    require 'media'

    @config = Nanoc::Int::ConfigLoader.new.new_from_cwd

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    audio_file = arguments[0]

    # Verify that audio file exists
    if !File.exist?(audio_file) 
      raise Nanoc::Int::Errors::GenericTrivial, "audio file does not exist"
    end

    # Verify the audio file is the right type
    if !ACCEPTED_FORMATS.include?(File.extname(audio_file).strip.downcase[1..-1])
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "audio file must be one of the following: #{ACCEPTED_FORMATS.join(' ')}"
      )
    end

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    $stderr.print 'Probing audio file… '
    $stderr.flush
    probe = Media.probe(audio_file)
    duration = probe.format.duration.to_f / 60
    $stderr.puts 'done'

    ibm = JSON.parse(File.read(client_secrets_path), object_class: Credentials)

    uri = URI.parse(ibm.url + '/v1/recognize')
    params = {
      timestamps: true,
      smart_formatting: true,
      speaker_labels: true,
      inactivity_timeout: -1
    }
    uri.query = URI.encode_www_form(params)

    audio_data = File.binread(audio_file)

    req = Net::HTTP::Post.new uri
    req.basic_auth(ibm.username, ibm.password)
    req.body = audio_data
    req.content_type = "audio/#{File.extname(audio_file).delete('.')}"

    $stderr.print "Starting recognition of #{duration.round} minutes of audio… "
    $stderr.flush
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.read_timeout = 5 * 60
    http.set_debug_output($stderr) if debug?

    start = Time.now
    res = http.start { |connection| connection.request(req) }
    $stderr.puts 'done'

    case res
    when Net::HTTPSuccess
      response_duration = ((Time.now - start) / 60).round
      $stderr.puts 'Audio recognition request finished successfully in about ' \
                   "#{response_duration} minutes"

      meeting_dir, audio_name = File.split(audio_file)
      recognition_file = File.join(meeting_dir, File.basename(audio_name, '.*') + '.json')
      write(recognition_file, res.body)
    else
      res.value
    end
  end

  private

  def write(filename, content)
    File.write(filename, content)
    Nanoc::Int::NotificationCenter.post(:file_created, filename)
  end

  def client_secrets_path
    well_known_path_for('client_secrets.json')
  end

  def well_known_path_for(file)
    File.join(@config[:ibm][:credentials_path], file)
  end
end

runner RecognizeAudio
