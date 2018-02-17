# frozen_string_literal: true

require_relative '../lib/helpers/mixins/google_api_support'

usage 'import-notes [options] doc_id'
aliases :import_notes, :in
summary 'import the notes of a meeting'
description 'Import the Google Doc notes of a meeting'

class ImportNotes < ::Nanoc::CLI::CommandRunner
  include GoogleApiSupport

  def run
    require 'google/apis/drive_v2'

    @config = Nanoc::Int::ConfigLoader.new.new_from_cwd

    # Extract arguments
    if arguments.length != 1
      raise Nanoc::Int::Errors::GenericTrivial, "usage: #{command.usage}"
    end
    doc_id = arguments[0]

    # Setup notifications
    Nanoc::Int::NotificationCenter.on(:file_created) do |file_path|
      Nanoc::CLI::Logger.instance.file(:high, :create, file_path)
    end

    service = Google::Apis::DriveV2::DriveService.new
    service.client_options.application_name = @config[:google][:application_name]
    service.client_options.log_http_requests = debug?
    service.authorization = user_credentials_for(Google::Apis::DriveV2::AUTH_DRIVE)
    doc = service.get_file(doc_id,
                           fields: 'alternateLink,createdDate,description,embedLink,etag,iconLink,id,kind,lastModifyingUser(displayName,emailAddress,kind,picture),mimeType,modifiedDate,title,version')

    docs_cache = @config[:cache][:meeting_notes]
    FileUtils.mkdir_p(docs_cache)
    doc_file = File.join(docs_cache, "#{doc.id}.yaml")
    File.write(doc_file, YAML.dump(doc.to_h))
    Nanoc::Int::NotificationCenter.post(:file_created, doc_file)
  end
end

runner ImportNotes
