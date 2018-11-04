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
        if params["action"] == "deleted"
          delete_repository repository
        else
          create_repository(params["installation"], repository)
        end
      end
    when 'installation_repositories'
      params["repositories_added"].each do |repository|
        create_repository(params["installation"], repository)
      end
      params["repositories_removed"].each do |repository|
        delete_repository repository
      end
    end

    render json: {}
  end

  private def create_repository(installation, data)
    Repository.create(
      installation_id: installation["id"],
      repo_name: data["full_name"],
      directory: "/"
    )
  end

  private def delete_repository data
    Repository.where(repo_name: data["full_name"]).destroy_all
  end
end
