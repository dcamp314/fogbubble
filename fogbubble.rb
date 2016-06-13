#!/usr/bin/env -S ruby -W

require 'curses'
include Curses

class MyWindow < Window
  def fmtCase; "%8d  %.#{maxx - 10}s"; end

  def acs; attron(A_ALTCHARSET) { yield }; end
  def rvideo; attron(A_REVERSE) { yield }; end
  def mvprintw(y, x, fmt, *args); setpos(y, x); addstr(sprintf(fmt, *args)); end
end

begin
  init_screen
  noecho
  curs_set 0

  windows = []  # keep a list of windows

  # overwrite default stdscr with a MyWindow
  windows << stdscr = MyWindow.new(lines, cols, 0, 0)

  # create left-hand side window (resolved cases)
  windows << lhs = MyWindow.new(lines - 4, (cols - 1) / 2, 0, 0)

  # create right-hand side window (active cases)
  windows << rhs = MyWindow.new(lines - 4, cols / 2, 0, cols - (cols / 2))

  # create "Working On" window
  windows << won = MyWindow.new(2, cols, lines - 4, 0)
  won.rvideo { won.addstr(" Working On ") }

  # create clock/ticker window
  windows << clk = MyWindow.new(2, cols, lines - 2, 0)
  fmtClk = "%H:%M:%S"

  # draw border around rhs
  begin
    # draw vertical line between lhs & rhs
    (0...rhs.maxy).each do |i|
      stdscr.setpos(i, rhs.begx - 1)
      stdscr.acs { stdscr.addch('x') }  # poor man's ACS_VLINE
    end

    # draw remainder of border on won
    won.setpos(0, rhs.begx - 1)
    won.acs { won.addstr('m' + 'q' * rhs.maxx) }  # poor man's ACS_LLCORNER & ACS_HLINE
  end

  loop do
    won.mvprintw(1, 0, won.fmtCase, 94108, "San Francisco Lindy Exchange")

    clk.setpos(0, 0)
    clk.acs { clk.addstr('q' * cols) }  # poor man's ACS_HLINE

    clk.setpos(0, 0)
    clk.rvideo { clk.addstr(Time.now.strftime(" #{fmtClk} ")) }

    # refresh windows & update screen
    windows.map(&:noutrefresh)
    doupdate

    # sleep for remainder of current wall clock second
    sleep(1 - 1e-6 * Time.now.usec)
  end

  # free windows
  windows.map(&:close)
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
