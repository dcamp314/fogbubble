require_relative 'fogbugz'

class Interval
  extend Enumerable

  def self.each(&block)
    @@list.each(&block)
  end

  attr_accessor :case, :utcStart, :utcEnd

  @@list = []

  def initialize(ixBug, utcStart, utcEnd)
    @case      = Case.find_or_new(ixBug)
    @utcStart  = utcStart
    @utcEnd    = utcEnd
  end

  def self.fetch
    utcLookBackEnd   = Time.now.utc
    utcLookBackStart = utcLookBackEnd - Config.cLookBackPeriodDays * 86400

    # FogBugz intervals are always less than 24 hours, so beginning the listing a day early is
    # sufficient to catch intervals starting before but ending within the look-back period
    utcListStart     = utcLookBackStart - 86400

    tmpList = []
    FogBugz.listIntervals(dtStart: FogBugz.dtFromUtc(utcListStart)).
      elements.each("//interval") do |i|

      ixBug    = i.text("ixBug"  ).to_i
      dtStart  = i.text("dtStart")
      dtEnd    = i.text("dtEnd"  )  # text() returns nil if the tag is empty
      utcEnd   = dtEnd ? FogBugz.utcFromDt(dtEnd) : nil

      # clip older intervals to start of look-back period
      utcStart = [FogBugz.utcFromDt(dtStart), utcLookBackStart].max
      utcEnd   = [utcEnd,                     utcLookBackStart].max if utcEnd

      # record unless clipped duration is 0
      tmpList << new(ixBug, utcStart, utcEnd) unless utcEnd && (utcStart == utcEnd)
    end
    @@list = tmpList.sort_by(&:utcStart)  # atomic update of @@list
  end

  def self.age!
    utcLookBackEnd   = Time.now.utc
    utcLookBackStart = utcLookBackEnd - Config.cLookBackPeriodDays * 86400

    # discard expired intervals
    while !@@list.empty? do
      utcEnd = @@list.first.utcEnd
      if utcEnd && (utcEnd <= utcLookBackStart)
        @@list.shift
        next
      else
        break
      end
    end

    # clip oldest interval to start of look-back period
    if !@@list.empty? && @@list.first.utcStart < utcLookBackStart
      @@list.first.utcStart = utcLookBackStart
    end
  end

  def hrsWorkedInLookBackPeriod
    if utcEnd
      (utcEnd - utcStart) / 3600
    else
      (Time.now.utc - utcStart) / 3600
    end
  end
end
