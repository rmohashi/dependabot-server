class DependenciesController < ApplicationController
  WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']

  protect_from_forgery with: :null_session

  def create
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
      params["repositories"].each do |repository|
        Repository.create(
          installation_id: params["installation"]["id"],
          repo_name: repository["full_name"],
          directory: "/"
        )
      end
    end

    render json: {}
  end
end
