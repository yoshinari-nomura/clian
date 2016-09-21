require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'launchy'
require "thor"

module Clian
  # https://github.com/google/google-auth-library-ruby#example-command-line
  # https://github.com/google/google-api-ruby-client#example-usage
  # http://stackoverflow.com/questions/12572723/rails-google-client-api-unable-to-exchange-a-refresh-token-for-access-token
  #
  class Authorizer
    def initialize(client_id, client_secret, scope, token_store_path)
      @authorizer = Google::Auth::UserAuthorizer.new(
        Google::Auth::ClientId.new(client_id, client_secret),
        scope,
        Google::Auth::Stores::FileTokenStore.new(file: token_store_path)
      )
    end

    def credentials(user_id = "default")
      @authorizer.get_credentials(user_id)
    end

    def auth_interactively(user_id = "default", shell = Thor.new.shell)
      oob_uri = "urn:ietf:wg:oauth:2.0:oob"

      url = @authorizer.get_authorization_url(base_url: oob_uri)
      begin
        Launchy.open(url)
      rescue
        puts "Open URL in your browser:\n #{url}"
      end

      code = shell.ask "Enter the resulting code:"

      @authorizer.get_and_store_credentials_from_code(
        user_id:  user_id,
        code:     code,
        base_url: oob_uri
      )
    end
  end # Authorizer
end # Clian
