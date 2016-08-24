#!/usr/bin/env -S ruby

require_relative 'fogbubble/curses'
require_relative 'fogbubble/fogbugz'
require_relative 'fogbubble/case'
require_relative 'fogbubble/project'
require_relative 'fogbubble/interval'

begin
  init_screen
  noecho
  curs_set 0

  thrFetch               = nil
  thrWOn                 = nil
  workingOnPrev          = nil
  utcRecordProtectedNext = nil
  loop do
    fail "terminal too small" if lines < 5 || cols < 21
    sizePrev = [lines, cols]

    rgWindows = []  # keep a list of windows

    # create left-hand side window (resolved cases)
    rgWindows << winLHS = Window.new(lines - 4, (cols - 1) / 2, 0, 0)

    # create right-hand side window (active cases)
    rgWindows << winRHS = Window.new(lines - 4, cols / 2, 0, cols - (cols / 2))

    # create "Working On" window
    rgWindows << winWOn = Window.new(2, cols, lines - 4, 0)
    winWOn.blink { winWOn.rvideo { winWOn.addnstr(" Working On ") } }

    # create clock/ticker window
    rgWindows << winClk = Window.new(2, cols, lines - 2, 0)

    # draw border around winRHS
    winWOn.bold { winWOn.acs { winWOn.mvprintw(0, winRHS.begx - 1, ACS_LLCORNER + ACS_HLINE * winRHS.maxx) } }
    stdscr.bold { (0...winRHS.maxy).each { |i| stdscr.acs { stdscr.mvprintw(i, winRHS.begx - 1, ACS_VLINE) } } }
    stdscr.noutrefresh

    # background fetch of info
    thrFetch.join if thrFetch && thrFetch.status.nil?  # propagate any exceptions
    thrFetch   = nil if thrFetch && !thrFetch.status   # reset if terminated
    thrFetch ||= Thread.new do
      Interval.fetch
      Case.fetch_active
      Case.fetch_missing_details
      Project.fetch_protected
      Project.fetch_names
      Case.fetch_resolved
      Case.fetch_working_on
    end

    loop do
      # background fetch of Working On
      thrWOn.join if thrWOn && thrWOn.status.nil?  # propagate any exceptions
      thrWOn   = nil if thrWOn && !thrWOn.status   # reset if terminated
      thrWOn ||= Thread.new do
        sleep 60  # time until next fetch
        Case.fetch_working_on
      end

      # when Working On changes, trigger redraw & refetch of other info
      if Case.workingOn != workingOnPrev
        fInitialFetch = workingOnPrev.nil?
        workingOnPrev = Case.workingOn
        break unless fInitialFetch
      end

      cSecondsOffset =  # combined offset of timezone and nLogicalDayEnds
        Time.now.utc_offset - (Config.nLogicalDayEnds * 3600).to_i
      utcTodayLogicalStart =
        Time.at(
          ((Time.now.to_i + cSecondsOffset) / 86400 * 86400) - cSecondsOffset).
        utc

      # background record protected time allocations at start of each logical day
      utcRecordProtectedNext ||= utcTodayLogicalStart + 86400
      if Time.now >= utcRecordProtectedNext
        Thread.new { Project.record_protected }
        utcRecordProtectedNext = nil  # reset
      end

      # draw left-hand side
      winLHS.clear

      cListedDays = Config.cLookBackPeriodDays + 1  # always list today
      cRowsEveryDay, cDaysWithExtraRow = winLHS.maxy.divmod(cListedDays)

      (0...cListedDays).each do |d|
        cCaseRows  = cRowsEveryDay - 1  # first row is date heading
        # each of the first cDaysWithExtraRow days gets an extra row
        cCaseRows += 1 if d < cDaysWithExtraRow

        utcListStart = utcTodayLogicalStart - d * 86400
        utcListEnd   = utcListStart + 86400

        # date heading
        y = winLHS.maxy - cRowsEveryDay * (d + 1) - [d + 1, cDaysWithExtraRow].min
        winLHS.setpos(y, 0)
        winLHS.blink { winLHS.rvideo { winLHS.addnstr(utcListStart.strftime(" %s \n" % Config.fmtDate)) } }

        winLHS.bold do
          if Case.rgResolved.empty?
            winLHS.addnstr(" Loading...")
          else
            winLHS.setpos(y + 1, 0)

            # display up to cCaseRows cases resolved on this day
            Case.rgResolved.
              select { |c| (utcListStart...utcListEnd).include? c.utcResolved }.
              first(cCaseRows).
              each { |c| winLHS.addnstr("%s\n" % c) }
          end
        end
      end

      # draw right-hand side
      winRHS.clear
      winRHS.bold { winRHS.addnstr(" Loading...") } if Project.rgProtected.empty?
      Interval.age!
      Project.rgProtected.
        sort_by(&:hrsRemainingInLookBackPeriod).reverse_each do |p|
        if (hrsRemainingInLookBackPeriod =
            p.hrsRemainingInLookBackPeriod) > 0
          winRHS.blink { winRHS.rvideo { winRHS.addnstr(" %s \n" % p) } }

          cCaseRows = Math.
            log2(hrsRemainingInLookBackPeriod / Config.hrsLogarithmicReference).
            round
          cCaseRows = 1 if cCaseRows < 1  # always display at least one row given that any hrs remain

          rgFirstCases = Case.rgActive.
            select { |c| c.project == p }.
            first(cCaseRows)

          winRHS.bold do
            rgFirstCases.each do |c|
              winRHS.addnstr("%s\n" % c)
            end

            ((rgFirstCases.count + 1)..cCaseRows).each do |n|
              winRHS.addnstr("%s" % winRHS.fmtCase % [n, ""]) if $VERBOSE
              winRHS.addnstr("\n")
            end
          end
        end
      end

      # draw working on
      winWOn.setpos(1, 0)
      winWOn.clrtoeol
      winWOn.bold { winWOn.addnstr(Case.workingOn || " Loading...") }

      # draw clock
      winClk.bold { winClk.acs { winClk.mvprintw(0, 0, ACS_HLINE * cols) } }
      winClk.blink { winClk.rvideo { winClk.mvprintw(0, 0, Time.now.strftime(" %s " % Config.fmtClk)) } }

      # refresh windows & update screen
      rgWindows.each(&:noutrefresh)
      doupdate

      # sleep for remainder of current wall clock second
      sleep(1 - 1e-6 * Time.now.usec)

      # trigger redraw unless screen size is unchanged
      break unless [lines, cols].eql? sizePrev
    end

    # free windows
    rgWindows.each(&:close)
  end
rescue Interrupt  # Ctrl-C to break
ensure
  close_screen
end
