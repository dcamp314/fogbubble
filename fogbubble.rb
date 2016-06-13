#!/usr/bin/env -S ruby -W

require 'curses'
include Curses
require 'yaml'

ACS_ULCORNER = 'l'
ACS_LLCORNER = 'm'
ACS_URCORNER = 'k'
ACS_LRCORNER = 'j'
ACS_LTEE     = 't'
ACS_RTEE     = 'u'
ACS_BTEE     = 'v'
ACS_TTEE     = 'w'
ACS_HLINE    = 'q'
ACS_VLINE    = 'x'
ACS_PLUS     = 'n'

class MyWindow < Window
  def fmtCase; "%8d  %.#{maxx - 10}s"; end

  def acs; attron(A_ALTCHARSET) { yield }; end
  def rvideo; attron(A_REVERSE) { yield }; end
  def mvprintw(y, x, fmt, *args); setpos(y, x); addstr(sprintf(fmt, *args)); end
end

class Config
  @@defaults = YAML.load_file(File.expand_path("defaults.yaml", File.dirname($0)))
  @@config   = YAML.load_file(File.expand_path("config.yaml",   File.dirname($0)))
  @@user     = YAML.load_file(File.expand_path("~/.fogbubble/config.yaml")) rescue {}

  def self.method_missing(k)
    @@user[k.to_s] || @@config[k.to_s] || @@defaults[k.to_s]
  end
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

  # draw border around rhs
  begin
    # draw vertical line between lhs & rhs
    (0...rhs.maxy).each do |i|
      stdscr.setpos(i, rhs.begx - 1)
      stdscr.acs { stdscr.addch(ACS_VLINE) }
    end

    # draw remainder of border on won
    won.setpos(0, rhs.begx - 1)
    won.acs { won.addstr(ACS_LLCORNER + ACS_HLINE * rhs.maxx) }
  end

  loop do
    lhs.rvideo { lhs.mvprintw 0, 0, Time.now.strftime(" #{Config.fmtDate} ") }

    won.mvprintw(1, 0, won.fmtCase, 94108, "San Francisco Lindy Exchange")

    clk.setpos(0, 0)
    clk.acs { clk.addstr(ACS_HLINE * cols) }

    clk.setpos(0, 0)
    clk.rvideo { clk.addstr(Time.now.strftime(" #{Config.fmtClk} ")) }

    # refresh windows & update screen
    windows.each(&:noutrefresh)
    doupdate

    # sleep for remainder of current wall clock second
    sleep(1 - 1e-6 * Time.now.usec)
  end

  # free windows
  windows.each(&:close)
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
