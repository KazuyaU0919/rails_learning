set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:schema:load:cache
bundle exec rails db:migrate
