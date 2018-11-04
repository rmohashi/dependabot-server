namespace :dependency do
  desc "Check and create PR for the repositories"
  task check_for_updates: :environment do
    Repository.all.each do |repository|
      Dependency::Checker.run(repository)
    end
  end

end
