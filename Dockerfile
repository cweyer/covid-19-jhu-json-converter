FROM ruby:2-slim-buster

WORKDIR /exporter
COPY . .

CMD ["/usr/local/bin/ruby", "jhu2json.rb"]
