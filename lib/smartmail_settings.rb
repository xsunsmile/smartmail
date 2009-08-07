
class SMSetting

  @@config = 'config/config.yml'

  def self.load( config_file=nil )
    @@config = config_file if config_file
    settings = YAML.load_file(@@config)
    settings
  end

end
