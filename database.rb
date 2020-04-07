require 'uri'
require 'slop'
require 'mysql2'
require 'postgresql'
require 'sqlite3'
require 'active_record'

# Parses the config parameters for the database configuration and
# access credentials, as well as options. This code snipped was taken
# from https://gist.github.com/pricees/9630464 and slightly adapted.
def database_configuration
  uri    = URI.parse(OPTIONS[:credentials])
  qs     = uri.query ? Hash[URI::decode_www_form(uri.query)] : {}
  ui     = uri.userinfo ? uri.userinfo.split(':') : Array.new { nil }

  ports = {
    postgres: 5432,
    mysql: 3306,
    sqlite: nil
  }.with_indifferent_access

  encodings = {
    postgres: "utf-8",
    mysql: "utf8",
    sqlite: "utf-8"
  }.with_indifferent_access

  adapters = {
    postgres: "postgresql",
    mysql: "mysql2",
    sqlite: "sqlite"
  }.with_indifferent_access

  puts "SSLCA: #{OPTIONS[:ssl_ca]}"

  {
    encoding:   qs["encoding"] || encodings[uri.scheme] ,
    adapter:    adapters[uri.scheme],
    host:       uri.host,
    port:       uri.port || ports[uri.scheme],
    database:   uri.path[1..-1],
    username:   ui.first,
    password:   ui.last,
    reconnect:  qs["reconnect"] || true,
    pool:       qs["pool"] || 5,
    sslca:      OPTIONS[:ssl_ca]
  }
end

# Establish a database connection
ActiveRecord::Base.establish_connection(database_configuration)
