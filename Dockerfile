# Dockerfile
FROM ruby:3.3

# node は使う（esbuild など）/ yarn は使わない
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends nodejs postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY . .

# portsは3000でExpose
EXPOSE 3000

# dev server起動
CMD ["bin/dev"]
