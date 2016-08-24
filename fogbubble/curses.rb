# xterm-acs-brightbg|dcamp:\
#         :ac=l\332m\300k\277j\331u\264t\303v\301w\302q\304x\263n\305`^Da\260f\370g\361~\371.^Y-^Xh\261i^U0\333y\363z\362:\
#         :mb=\E[5m:\
#         :tc=xterm:
#
# cap_mkdb -f /usr/share/misc/termcap /etc/termcap

require 'curses'; include Curses

# add some methods to Curses::Window
class Window
  def acs
    attron(A_ALTCHARSET) { yield }
  end

  def blink  # bright background
    attron(A_BLINK) { yield }
  end

  def bold
    attron(A_BOLD) { yield }
  end

  def rvideo
    attron(A_REVERSE) { yield }
  end

  def underline
    attron(A_UNDERLINE) { yield }
  end

  def mvprintw(y, x, fmt, *args)
    return if y >= maxy || x >= maxx
    setpos(y, x)
    addstr(sprintf(fmt.to_s, *args))
  end

  # str truncated after n chars
  # (or at end of line if n == -1 or not given)
  def addnstr(str, n = -1)
    n = maxx - curx if n == -1
    addstr(str.to_s[0, n])
  end

  # str truncated at end of line
  # cursor not advanced
  def addchstr(str)
    y, x = cury, curx
    addstr(str.to_s[0, maxx - x])
    setpos(y, x)
  end

  def fmtCase
    "%8d  %.#{maxx - 10}s"
  end
end

ACS_ULCORNER = 'l'; ACS_LLCORNER = 'm'; ACS_URCORNER = 'k'; ACS_LRCORNER = 'j'
ACS_LTEE     = 't'; ACS_RTEE     = 'u'; ACS_BTEE     = 'v'; ACS_TTEE     = 'w'
ACS_HLINE    = 'q'; ACS_VLINE    = 'x'; ACS_PLUS     = 'n'
#ACS_ULCORNER = "\332"; ACS_LLCORNER = "\300"; ACS_URCORNER = "\277"; ACS_LRCORNER = "\331"
#ACS_LTEE     = "\303"; ACS_RTEE     = "\264"; ACS_BTEE     = "\301"; ACS_TTEE     = "\302"
#ACS_HLINE    = "\304"; ACS_VLINE    = "\263"; ACS_PLUS     = "\305"
