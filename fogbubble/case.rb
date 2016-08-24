require_relative 'fogbugz'

class Case
  attr_accessor :ixBug, :sTitle, :project, :utcResolved

  @@list       = []
  @@rgActive   = []
  @@rgResolved = []
  @@workingOn  = nil

  def initialize(ixBug)
    @ixBug = ixBug
    @@list << self
  end

  def self.find_or_new(ixBug)
    @@list.find { |c| c.ixBug == ixBug } || new(ixBug)
  end

  def self.fetch_active
    @@rgActive =
      FogBugz.search(q: "assignedto:me status:active",
                     cols: "ixBug,sTitle,ixProject").
                     get_elements("//case").
                     map do |e|
                       c = Case.find_or_new(e.text("ixBug").to_i)

                       c.sTitle  = e.text("sTitle")
                       c.project = Project.find_or_new(e.text("ixProject").to_i)

                       c
                     end
  end

  def self.rgActive
    @@rgActive
  end

  def self.fetch_resolved
    cListedDays  = Config.cLookBackPeriodDays + 1  # always list today
    utcListStart = Time.now.utc - cListedDays * 86400

    @@rgResolved =
      FogBugz.search(q: "resolvedby:me resolved:'%s..now'" %
                     FogBugz.dtFromUtc(utcListStart),
                     cols: "ixBug,sTitle,ixProject,dtResolved").
                     get_elements("//case").
                     map do |e|
                       c = Case.find_or_new(e.text("ixBug").to_i)

                       c.sTitle      = e.text("sTitle")
                       c.project     = Project.find_or_new(e.text("ixProject").to_i)
                       c.utcResolved = FogBugz.utcFromDt(e.text("dtResolved"))

                       c
                     end
  end

  def self.rgResolved
    @@rgResolved
  end

  def self.fetch_working_on
    @@workingOn =
      Case.find_or_new(FogBugz.viewPerson.
                       text("//ixBugWorkingOn").to_i)
  end

  def self.workingOn
    @@workingOn
  end

  def self.fetch_missing_details
    rgCaseMissingDetails  = @@list.reject { |c| c.sTitle && c.project }

    return if rgCaseMissingDetails.empty?

    rgIxBugMissingDetails = rgCaseMissingDetails.map { |c| c.ixBug }

    FogBugz.search(q: rgIxBugMissingDetails.join(','),
                   cols: "ixBug,sTitle,ixProject").
                   get_elements("//case").
                   map do |e|
                     c = Case.find_or_new(e.text("ixBug").to_i)

                     c.sTitle  = e.text("sTitle")
                     c.project = Project.find_or_new(e.text("ixProject").to_i)

                     c
                   end
  end

  def to_s
    if ixBug > 0
      "%8d  %s" % [ixBug, sTitle]
    else
      "          Nothing"
    end
  end
end
