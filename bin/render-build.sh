set -o errexit

# ---- JS deps & Tailwind build ----
export NPM_CONFIG_PRODUCTION=false

if command -v npm >/dev/null 2>&1; then
  npm ci --include=dev
  npm run build:css
fi

# ---- Ruby deps & Rails tasks ----
bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
