# lib/tasks/versions.rake
namespace :versions do
  desc "Clean up PaperTrail versions by age and per-item limit"
  task cleanup: :environment do
    VersionsCleanupJob.perform_now
    puts "Versions cleanup finished."
  end
end
