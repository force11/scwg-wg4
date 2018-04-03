# frozen_string_literal: true

require_relative '../lib/mixins/google_api_support'

usage 'create-notes [options] html_agenda'
aliases :create_notes, :cn
summary 'create notes from a meeting agenda'
description 'Create a working agenda and a space for meeting notes from the given HTML meeting agenda.'

class CreateNotes < ::Nanoc::CLI::CommandRunner
  include GoogleApiSupport

  def run
    require 'nokogiri'
    require 'google/apis/drive_v2'

    @config = Nanoc::Int::ConfigLoader.new.new_from_cwd

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    agenda_path = arguments[0]

    if !File.exist?(agenda_path) || File.extname(agenda_path) != '.html'
      raise(
        Nanoc::Int::Errors::GenericTrivial,
        "The meeting notes were not created because '#{agenda_path}' was not found " \
        'or is not an HTML file.'
      )
    end

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    agenda = Nokogiri::HTML(File.read(agenda_path))
    file_metadata = {
      title: agenda.title,
      mime_type: 'application/vnd.google-apps.document'
    }

    service = Google::Apis::DriveV2::DriveService.new
    service.client_options.application_name = @config[:google][:application_name]
    service.client_options.log_http_requests = debug?
    service.authorization = user_credentials_for(Google::Apis::DriveV2::AUTH_DRIVE_FILE)
    doc = service.insert_file(file_metadata,
                              convert: true,
                              fields: 'alternateLink,createdDate,description,embedLink,etag,iconLink,id,kind,lastModifyingUser(displayName,emailAddress,kind,picture),mimeType,modifiedDate,title,version',
                              upload_source: agenda_path,
                              content_type: 'text/html')
    service.insert_child(@config[:google][:agenda_subfolder_id], doc) unless debug?
    Nanoc::Int::NotificationCenter.post(:file_created, doc.alternate_link)

    docs_cache = @config[:cache][:meeting_notes]
    FileUtils.mkdir_p(docs_cache)
    doc_file = File.join(docs_cache, "#{doc.id}.yaml")
    File.write(doc_file, YAML.dump(doc.to_h))
    Nanoc::Int::NotificationCenter.post(:file_created, doc_file)
  end
end

runner CreateNotes
