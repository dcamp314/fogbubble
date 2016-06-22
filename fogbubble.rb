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

# add some methods to Curses::Window
class Window
  def acs; attron(A_ALTCHARSET) { yield }; end
  def rvideo; attron(A_REVERSE) { yield }; end
  def mvprintw(y, x, fmt, *args); setpos(y, x); addstr(sprintf(fmt, *args)); end

  def fmtCase; "%8d  %.#{maxx - 10}s"; end
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

  loop do
    fail "terminal too small" if lines < 5 || cols < 21
    previous = [lines, cols]

    windows = []  # keep a list of windows

    # create left-hand side window (resolved cases)
    windows << lhs = Window.new(lines - 4, (cols - 1) / 2, 0, 0)

    # create right-hand side window (active cases)
    windows << rhs = Window.new(lines - 4, cols / 2, 0, cols - (cols / 2))

    # create "Working On" window
    windows << won = Window.new(2, cols, lines - 4, 0)
    won.rvideo { won.addstr(" Working On ") }

    # create clock/ticker window
    windows << clk = Window.new(2, cols, lines - 2, 0)

    # draw border around rhs
    won.acs { won.mvprintw(0, rhs.begx - 1, ACS_LLCORNER + ACS_HLINE * rhs.maxx) }
    (0...rhs.maxy).each { |i| stdscr.acs { stdscr.mvprintw(i, rhs.begx - 1, ACS_VLINE) } }
    stdscr.noutrefresh

    loop do
      lhs.rvideo { lhs.mvprintw 0, 0, Time.now.strftime(" #{Config.fmtDate} ") }

      won.mvprintw(1, 0, won.fmtCase, 94108, "San Francisco Lindy Exchange")

      clk.acs { clk.mvprintw(0, 0, ACS_HLINE * cols) }
      clk.rvideo { clk.mvprintw(0, 0, Time.now.strftime(" #{Config.fmtClk} ")) }

      # refresh windows & update screen
      windows.each(&:noutrefresh)
      doupdate

      # sleep for remainder of current wall clock second
      sleep(1 - 1e-6 * Time.now.usec)

      # trigger redraw unless screen size is unchanged
      break unless [lines, cols].eql? previous
    end

    # free windows
    windows.each(&:close)
  end
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
