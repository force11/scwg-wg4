# frozen_string_literal: true

usage 'create-agenda [options] date & time (in UTC)'
aliases :create_agenda, :ca
summary 'create a meeting agenda'
description 'Create a new meeting agenda for the given UTC date and time.'
flag nil, :force, 'force creation of new agenda'

class CreateAgenda < ::Nanoc::CLI::CommandRunner

  def run
    require 'chronic'
    require 'active_support/core_ext/time/zones'
    require 'active_support/core_ext/time/conversions'

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end

    Time.zone = 'UTC'
    Chronic.time_class = Time.zone
    meeting_time = Chronic.parse(arguments[0])
    #config = Nanoc::Int::ConfigLoader.new.new_from_cwd
    path = "items/meetings/#{meeting_time.strftime('%F')}/"

    # Check whether agenda exists
    if File.exist?(path) && (!File.directory?(path) || !(Dir.entries(path) - %w[. ..]).empty?) && !options[:force]
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The agenda was not created because '#{path}' already exists. " \
        'Re-run the command using --force to create the agenda anyway.',
      )
    end

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    # Build entire site
    FileUtils.mkdir_p(path)
    FileUtils.cd(File.join(path)) do
      write('agenda.md', <<~EOS
    ---
    title: #{meeting_time.strftime('%F')} SCWG WG4 Weekly Meeting
    meeting_time: #{meeting_time}
    message:
    ---

    1 Agenda review
    2 Introductions to new people
    3 Status of current action items
      - Start a narrative of our progress https://goo.gl/xs496P [CHRIS - DONE]
      - Add to the scenarios. https://goo.gl/XikbTf [ONGOING]
      - Add to the questions to consider: https://goo.gl/MxA41E [ONGOING]
    4 Our goal and how we can productively work towards it
      - Discussion on how to track proposed topics and our progress/analysis
    5 Various discussion topics (as time permits)
      - Scenarios: https://goo.gl/XikbTf
      - Questions to consider: https://goo.gl/MxA41E
      - Technologies: https://goo.gl/8r822b
    6 Action items and suggestions for next week's agenda
EOS
           )
    end

    puts "Created an agenda at '#{path}' for " \
         "#{meeting_time.to_time.to_s(:long_ordinal)} (#{meeting_time.strftime('%H:%M %Z')}). Enjoy!"
  end

  private

  def write(filename, content)
    File.write(filename, content)
    Nanoc::Int::NotificationCenter.post(:file_created, filename)
  end
end

runner CreateAgenda
