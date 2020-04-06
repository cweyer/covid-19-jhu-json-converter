FROM ruby:2-slim-buster

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential \
      default-libmysqlclient-dev \
      libpq-dev \
      libsqlite3-dev \
    && apt-get clean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /exporter
COPY . .

RUN bundle install

CMD ["/usr/local/bin/ruby", "jhu2json.rb"]
