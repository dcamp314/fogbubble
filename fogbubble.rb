#!/usr/bin/env -S ruby -W

require 'curses'
include Curses

class MyWindow < Window
  attr_reader :getmaxy, :getmaxx, :getbegy, :getbegx

  def initialize(h, w, y, x)
    @getmaxy, @getmaxx, @getbegy, @getbegx = h, w, y, x
    super
  end

  def fmtCase; "%8d  %.#{getmaxx - 10}s"; end

  def rvideo; attron(A_REVERSE) { yield }; end
  def mvprintw(y, x, fmt, *args); setpos(y, x); addstr(sprintf(fmt, *args)); end
end

begin
  init_screen
  noecho
  curs_set 0

  windows = []  # keep a list of windows

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
    (0...rhs.getmaxy).each do |i|
      stdscr.setpos(i, rhs.getbegx - 1)
      stdscr.attron(A_ALTCHARSET) { stdscr.addch('x') }  # poor man's ACS_VLINE
    end
    stdscr.noutrefresh

    # draw remainder of border on won
    won.setpos(0, rhs.getbegx - 1)
    won.attron(A_ALTCHARSET) do
      won.addch('m')                 # poor man's ACS_LLCORNER
      won.addstr('q' * rhs.getmaxx)  # poor man's ACS_HLINE
    end
  end

  loop do
    won.mvprintw(1, 0, won.fmtCase, 94108, "San Francisco Lindy Exchange")

    clk.setpos(0, 0)
    clk.attron(A_ALTCHARSET) { clk.addstr('q' * cols) }  # poor man's ACS_HLINE

    clk.setpos(0, 0)
    clk.rvideo { clk.addstr(Time.now.strftime(" #{fmtClk} ")) }

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
