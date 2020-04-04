FROM ruby:2-slim-buster

WORKDIR /exporter
COPY . .

RUN bundle install

CMD ["/usr/local/bin/ruby", "jhu2json.rb"]
