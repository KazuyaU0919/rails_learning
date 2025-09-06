# Dockerfile
# ベースは公式 Ruby イメージ（Debian 系）
FROM ruby:3.3

# ---- OS パッケージの導入（1RUNにまとめてレイヤを減らす）----
# - apt-get update         : パッケージリスト更新
# - nodejs                 : importmap / esbuild 等で必要になることがある（不要なら外してOK）
# - postgresql-client      : rails db:… で psql を使う場合に便利（不要なら外してOK）
# - libvips libvips-dev    : ActiveStorage の画像変換（variant）で vips を使うために必須
# - rm -rf /var/lib/apt/lists/* : APT キャッシュを削除してイメージを軽量化
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
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
