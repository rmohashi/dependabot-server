class DependenciesController < ApplicationController
  protect_from_forgery with: :null_session

  PRIVATE_KEY = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n")) # convert newlines
  WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']
  APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']

  def create
    payload = {
        iat: Time.now.to_i,
        exp: Time.now.to_i + (10 * 60),
        iss: APP_IDENTIFIER
    }
    jwt = JWT.encode(payload, PRIVATE_KEY, 'RS256')
    client = Octokit::Client.new(bearer_token: jwt)

    request.body.rewind
    payload_raw = request.body.read # We need the raw text of the body to check the webhook signature
    begin
      payload = JSON.parse payload_raw
    rescue
      payload = {}
    end

    their_signature_header = request.env['HTTP_X_HUB_SIGNATURE'] || 'sha1='
    method, their_digest = their_signature_header.split('=')
    our_digest = OpenSSL::HMAC.hexdigest(method, WEBHOOK_SECRET, payload_raw)
    unless their_digest == our_digest
      render json: {}, status: 401
    end

    puts "---- received event #{request.env['HTTP_X_GITHUB_EVENT']}"
    puts "----         action #{payload['action']}" unless payload['action'].nil?

    case request.env['HTTP_X_GITHUB_EVENT']
    when 'installation'
      installation_id = payload['installation']['id']
      installation_token = client.create_app_installation_access_token(installation_id)[:token]
      puts 'Installation token: ' + installation_token
    end

    render json: {}
  end
end
