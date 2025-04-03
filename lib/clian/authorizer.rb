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
      callback_uri = "http://localhost:8000"

      url = @authorizer.get_authorization_url(base_url: callback_uri)
      begin
        Launchy.open(url)
      rescue
        puts "Open URL in your browser:\n #{url}"
      end

      puts "Waiting OAuth code at #{callback_uri} ..."

      code = get_oauth_code_by_webserver(8000) ||
             shell.ask("Enter the resulting code:")
      puts "Done."

      @authorizer.get_and_store_credentials_from_code(
        user_id:  user_id,
        code:     code,
        base_url: callback_uri
      )
    end

    private

    def get_oauth_code_by_webserver(port = 8000)
      require 'webrick'
      require 'uri'

      code = nil
      server = WEBrick::HTTPServer.new(
        Port: port,
        Logger: WEBrick::Log.new(File.open(File::NULL, "w")),
        AccessLog: []
      )

      server.mount_proc '/' do |req, res|
        query = URI.decode_www_form(req.query_string || "").to_h
        code = query["code"]

        if code
          res.status = 200
          res.content_type = "text/plain"
          res.body = "Got OAuth code: #{code}\nYou can close this browser and back to CLI."

          # shutdown server in another thread to avoid blocking current request
          Thread.new { server.shutdown }
        else
          res.status = 400
          res.body = "Failed to get OAuth code"
        end
      end

      # block until shutdown is called in another thread
      server.start
      return code
    end

  end # Authorizer
end # Clian
