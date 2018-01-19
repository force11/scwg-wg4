# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

module GoogleApiSupport

  OOB_URI ||= 'urn:ietf:wg:oauth:2.0:oob'

  def client_secrets_path
    well_known_path_for('client_secrets.json')
  end

  def token_store_path
    well_known_path_for('credentials.yaml')
  end

  def well_known_path_for(file)
    File.join('.config', 'google', file)
  end

  # Returns user credentials for the given scope. Requests authorization if
  # required.
  def user_credentials_for(scope)
    FileUtils.mkdir_p(File.dirname(token_store_path))

    client_id = Google::Auth::ClientId.from_file(client_secrets_path)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: token_store_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

    user_id = 'default'

    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      $stderr.puts "Open the following URL in your browser and authorize the application."
      $stderr.puts url
      code = $stdin.gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
