# frozen_string_literal: true

usage 'create-agenda [options] date & time'
aliases :create_agenda, :ca
summary 'create a meeting agenda'
description 'Create a new meeting agenda for the given date and time.'
flag nil, :force, 'force creation of new agenda'

class CreateAgenda < ::Nanoc::CLI::CommandRunner

  def run
    require 'chronic'

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end

    meeting_time = Chronic.parse(arguments[0])
    path = "items/meetings/#{meeting_time.strftime('%F')}/"

    # Check whether agenda exists
    if File.exist?(path) && !options[:force]
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

    # Build agenda
    FileUtils.mkdir_p(path)

    agenda = <<~EOS
    ---
    title: #{meeting_time.strftime('%F')} Agenda
    meeting_time: #{meeting_time.utc.iso8601}
    ---
    # Proposed Agenda

    1. Agenda review
    2. Introductions to new people
    3. Status of current action items
    4. Our goal and how we can productively work towards it
    5. Various discussion topics (as time permits)
    6. Action items and suggestions for next week's agenda
    7. Post call summary and wrap-up
EOS

    write(File.join(path, 'agenda.md'), agenda)
  end

  private

  def write(filename, content)
    File.write(filename, content)
    Nanoc::Int::NotificationCenter.post(:file_created, filename)
  end
end

runner CreateAgenda
