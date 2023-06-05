FROM ruby:3.1.2-alpine3.16

# bash is required for build scripts
# tzdata is a runtime dependency for ActiveSupport
# postgresql-libs is a runtime dependency for the database
# gcompat is needed for Nokogiri pre-built gems to work

RUN gem install bundler -v '~>2.3' && \
    bundle config --global frozen 1 && \
    apk add --no-cache coreutils bash tzdata postgresql-libs postgresql14-client gcompat && \
    truncate -s 0 /var/log/*log

WORKDIR /app

COPY Gemfile Gemfile.lock ./

# Temporarily add the dev packages required for to install bundles (and remove the build cache afterwards )
RUN apk add --no-cache --virtual .gem-installdeps build-base git postgresql-dev && \
      bundle install -j6 && \
      rm -rf $GEM_HOME/cache && \
      apk del .gem-installdeps

RUN addgroup --gid 1000 ruby && \
      adduser --disabled-password --home /home/ruby --gecos "" --ingroup ruby --uid 1000 ruby

COPY . /app

RUN chmod -R 777 /app/tmp /app/log

USER 1000
