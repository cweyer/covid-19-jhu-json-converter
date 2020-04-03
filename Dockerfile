FROM ruby:2-slim-buster

WORKDIR /exporter
COPY jhu2json.rb .

CMD ["/usr/local/bin/ruby", "jhu2json.rb"]
