require_relative 'fogbugz'

class Project
  extend Enumerable

  def self.each(&block)
    @@list.each(&block)
  end

  attr_accessor :ixProject, :nPercent, :sProject

  @@list        = []
  @@rgProtected = []

  def initialize(ixProject)
    @ixProject = ixProject
    @sProject  = "Loading..."
    @@list << self
  end

  def self.find_or_new(ixProject)
    @@list.find { |p| p.ixProject == ixProject } || new(ixProject)
  end

  def self.fetch_protected
    r = FogBugz.listProjectPercentTime

    @@nPercentTimeAllOtherProjects =
      r.text("//nPercentTimeAllOtherProjects").to_i

    @@rgProtected =
      r.get_elements("//projectpercenttime").
      map do |e|
        p = Project.find_or_new(e.text("ixProject").to_i)

        p.nPercent = e.text("nPercent").to_i

        p
      end
  end

  def self.rgProtected
    @@rgProtected
  end

  def self.record_protected
    strTime = FogBugz.log_time
    fetch_protected
    fetch_names
    rgProtected.
      sort_by(&:ixProject).each do |p|
      warn "[%s] ixProject=%d,sProject=%s,nPercent=%d (%.2f hrs worked/%.2f hrs protected)" %
        [strTime,
         p.ixProject,
         p.sProject,
         p.nPercent,
         p.hrsWorkedInLookBackPeriod,
         p.hrsProtectedInLookBackPeriod]
    end
    warn "[%s] nPercentTimeAllOtherProjects=%d" %
      [strTime,
       @@nPercentTimeAllOtherProjects]
  end

  def self.fetch_names
    FogBugz.listProjects.
      elements.each("//project") do |e|

      p = Project.find_or_new(e.text("ixProject").to_i)

      p.sProject = e.text("sProject")
    end
  end

  def hrsProtectedInLookBackPeriod
    Config.hrsLookBackPeriod * nPercent / 100
  end

  def hrsWorkedInLookBackPeriod
    Interval.reduce(0) do |acc, i|
      i.case.project == self ?
        acc + i.hrsWorkedInLookBackPeriod :
        acc
    end
  end

  def hrsRemainingInLookBackPeriod
    [hrsProtectedInLookBackPeriod - hrsWorkedInLookBackPeriod, 0].max
  end

  def to_s
    "%s" % sProject
  end
end
