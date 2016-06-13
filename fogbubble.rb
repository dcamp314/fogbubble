#!/usr/bin/env -S ruby -W

require 'curses'
include Curses

begin
  init_screen
  noecho
  curs_set 0

  loop do
    sleep 1
  end
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
