#!/usr/bin/env -S ruby -W

require 'curses'
include Curses

begin
  init_screen
  noecho
  curs_set 0

  windows = []  # keep a list of windows

  # create left-hand side window (resolved cases)
  windows << lhs = Window.new(lines - 4, (cols - 1) / 2, 0, 0)

  # create right-hand side window (active cases)
  windows << rhs = Window.new(lines - 4, cols / 2, 0, cols - (cols / 2))

  # create "Working On" window
  windows << won = Window.new(2, cols, lines - 4, 0)
  won.attron(A_REVERSE) { won.addstr(" Working On ") }

  # create clock/ticker window
  windows << clk = Window.new(2, cols, lines - 2, 0)
  fmtClk = "%H:%M:%S"

  loop do
    clk.setpos(0, 0)
    clk.attron(A_ALTCHARSET) { clk.addstr('q' * cols) }  # poor man's ACS_HLINE

    clk.setpos(0, 0)
    clk.attron(A_REVERSE) { clk.addstr(Time.now.strftime(" #{fmtClk} ")) }

    # refresh
    windows.each {|w| w.noutrefresh }
    doupdate

    # sleep for remainder of current wall clock second
    sleep(1 - 1e-6 * Time.now.usec)
  end
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
