#!/usr/bin/env -S ruby -W

require 'curses'
include Curses

begin
  init_screen
  noecho
  curs_set 0

  clk = Window.new(2, cols, lines - 2, 0)
  fmtClk = "%H:%M:%S"

  loop do
    clk.setpos(0, 0)
    clk.addstr(Time.now.strftime(" #{fmtClk} "))
    clk.refresh

    # sleep for remainder of current wall clock second
    sleep(1 - 1e-6 * Time.now.usec)
  end
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
