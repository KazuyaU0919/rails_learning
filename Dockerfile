# Dockerfile
# ベースは公式 Ruby イメージ（Debian 系）
FROM ruby:3.3

# ---- OS パッケージの導入（1RUNにまとめてレイヤを減らす）----
# - cron                : whenever が crontab を呼ぶために必要
# - tzdata              : cron の時刻を JST に合わせたい場合に有用（Rails は既に Asia/Tokyo）
# - nodejs / npm        : 必要なら維持
# - postgresql-client   : 必要なら維持
# - libvips libvips-dev : ActiveStorage の variant 用
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      cron \
      tzdata \
      nodejs npm \
      postgresql-client \
      libvips \
      libvips-dev && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリ
WORKDIR /app

# 先に Gemfile だけコピー → bundle install のキャッシュを効かせる
COPY Gemfile* ./
RUN bundle install

# アプリ本体
COPY . .

# 開発で 3000 番を使う
EXPOSE 3000

# dev サーバ起動コマンド
CMD ["bin/dev"]
