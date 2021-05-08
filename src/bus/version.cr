class Bus
  VERSION = "0.1.0"

  struct Version
    def to_s
      Bus::VERSION
    end

    def self.major
      parts[0]
    end

    def self.minor
      parts[1]
    end

    def self.patch
      parts[2]
    end

    def self.parts
      VERSION.split(".", 3)
    end
  end
end
