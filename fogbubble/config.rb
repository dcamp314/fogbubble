require 'yaml'

class Config
  @@defaults = YAML.load_file(File.expand_path("defaults.yaml", File.dirname($0)))
  @@config   = YAML.load_file(File.expand_path("config.yaml",   File.dirname($0))) rescue {}
  @@user     = YAML.load_file(File.expand_path("~/.fogbubble/config.yaml"))        rescue {}

  def self.method_missing(param)
    k = param.to_s
    if @@user.has_key?(k) || @@config.has_key?(k) || @@defaults.has_key?(k)
      @@user[k] || @@config[k] || @@defaults[k]
    else
      raise "undefined configuration parameter '%s'" % k
    end
  end
end
