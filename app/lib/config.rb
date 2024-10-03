class Config
  class << self
    def get(key)
      ENV[key.to_s.upcase] || Rails.configuration.astral[key.to_s.downcase.to_sym]
    end

    def set(key, value)
      ENV[key.to_s.upcase] = value
    end

    def [](key)
      get(key)
    end

    def []=(key, value)
      set(key, value)
    end
  end
end
