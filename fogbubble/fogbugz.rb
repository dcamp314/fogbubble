require_relative 'config'
require 'erb'; include ERB::Util
require 'open-uri'
require 'rexml/document'; include REXML
require 'time'

class FogBugz
  def self.initialize
    puts "Connecting to FogBugz API at %s..." % Config.sFogBugzURL

    r = Document.new(open("%s/api.xml" % Config.sFogBugzURL)).root

    minversion = r.text("minversion").to_i
    warn MINVERSION_WARNING % minversion if minversion > 8

    @@api_url = "%s/%s" % [Config.sFogBugzURL, r.text("url")]
    token     = if Config.token.empty?
                  puts "Logging on to FogBugz API as user %s..." % Config.sEmail

                  logon(email: Config.sEmail, password: Config.sPassword).
                    text("token")
                else
                  Config.token
                end
    @@api_url << "token=%s&" % token
  end

  def self.method_missing(cmd, args = {})
    warn "[%s] %s(%s)" %
      [log_time,
       cmd, args] if $VERBOSE  # announce each API request

    r = Document.new(
      open(@@api_url +
           ["cmd=%s" % cmd,
            args.map { |k, v| "%s=%s" % [url_encode(k), url_encode(v)] }].
           join('&')), ignore_whitespace_nodes: :all).root

    if (e = r.elements["error"])
      raise e.text
    end

    r  # root REXML::Element
  end

  def self.dtFromUtc(utc)
    raise "%s is not in UTC" % utc.inspect if !utc.utc?

    utc.xmlschema
  end

  def self.utcFromDt(dt)
    utc = Time.xmlschema(dt)

    raise "%s is not in UTC" % utc.inspect if !utc.utc?

    utc
  end

  def self.log_time
    Time.now.strftime("%d/%b/%Y:%H:%M:%S %z")
  end

  MINVERSION_WARNING = <<HEREDOC
Warning: FogBubble was written for FogBugz 8.
Your FogBugz installation reports its compatibility "minversion" as %d.
The interface may have changed and broken compatibility. Trying anyway...
HEREDOC
end

FogBugz.initialize
