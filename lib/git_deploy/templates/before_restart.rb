#!/usr/bin/env ruby
require 'pty'

oldrev, newrev, refname, tag = ARGV

FRAMEWORK_DIR="/usr/share/php/fetch-cms-core"

def run(cmd)
  begin
    PTY.spawn( "umask 002 && #{cmd}" ) do |stdout, stdin, pid|
      begin
        # Do stuff with the output here. Just printing to show it works
        stdout.each { |line| indent line.chomp }
      rescue Errno::EIO
      end
    end
  rescue PTY::ChildExited
    exit($?.exitstatus)
  end
end

def log(string)
  system "echo $'\e[1G'\"-----> #{string}\""
end

def indent(string)
  system "echo $'\e[1G'\"       #{string}\""
end

system "echo '\e[1G'"
log "Publishing Fetch CMS #{tag}"

log "Installing dependencies with composer"
run "composer --no-interaction install"
indent "Dependencies installed"

log "Resolving engine versions"
node_version = File.read('.nvmrc').strip
indent "Using Node.js version: #{node_version}"

log "Installing dependencies with npm"
run "/usr/local/nvm/#{node_version}/bin/npm install"
indent "Dependencies installed"

log "Compiling assets with grunt"
run "grunt --no-color release 1> /dev/null"
log "Assets compiled"

log "Syncing to #{FRAMEWORK_DIR}/#{tag}"
run "rsync -lrpt --delete --exclude='.git' #{FRAMEWORK_DIR}/source/ #{FRAMEWORK_DIR}/#{tag}"
log "Done!"


system "echo '\e[1G'"
