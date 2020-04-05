require 'slop'

OPTIONS = Slop.parse do |o|
  o.bool '-h', '--help', 'help'
  # TODO: Make this an array and default to everything.
  o.string '-r', '--region', "input file region (default: global)", default: "global"
  o.string '-o', '--output', "output to file, database or STDOUT (default: STDOUT)"
  o.string '-f', '--filename', "use this file name when outputting to file (defaults to current date)"
  o.string '-c', '--credentials', "set database credentials as URI (example: postgres://user:password@localhost:1337/mydb)"
  o.on '--version', 'print the version' do
    puts VERSION
    exit
  end
end

if OPTIONS.help?
  puts OPTIONS
  exit
end
