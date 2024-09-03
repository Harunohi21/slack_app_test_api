ARG RUBY_VERSION=3.1.4
# FROM ruby:${RUBY_VERSION}-slim-bullseye
FROM ruby:${RUBY_VERSION}
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# RUN apt update -y && apt install -y \
#   build-essential \
#   libpq-dev \
#   openssl \
#   procps \
#   locales \
#   default-libmysqlclient-dev \
#   yarn \
#   nodejs \
#   cron \
#   postgresql-client \
#   && apt-get clean \
#   && rm -rf /var/lib/apt/lists/*

ENV ROOT="/app"
WORKDIR ${ROOT}

COPY Gemfile ${ROOT}/Gemfile
COPY Gemfile.lock ${ROOT}/Gemfile.lock
RUN bundle install

# RUN sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen \
#   && locale-gen
# ENV LANG=ja_JP.UTF-8 \
#     BUNDLE_PATH=vendor/bundle \
#     BUNDLE_APP_CONFIG=${ROOT}/.bundle

COPY . ${ROOT}

# entrypoint
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3005

CMD ["rails", "server", "-b", "0.0.0.0"]