# frozen_string_literal: true

require "fileutils"

class PpsFoodFeed
  class Meta
    # @return [PpsFoodFeed::Meta]
    def self.load
      path = PpsFoodFeed::META_DIR + "meta.json"
      h = path.exist? ? JSON.parse(File.read(path)) : {}
      return self.new(h)
    end

    def initialize(h)
      @h = h
    end

    def each(&)
      return @h.each(&)
    end

    def get(menu_name, menu_month, key)
      return @h.fetch(menu_name, nil)&.fetch(menu_month, nil)&.fetch(key.to_s, nil)
    end

    def set(menu_name, menu_month, key, value)
      @h[menu_name] ||= {}
      @h[menu_name][menu_month] ||= {}
      @h[menu_name][menu_month][key.to_s] = value
    end

    def save
      FileUtils.mkdir_p(PpsFoodFeed::META_DIR)
      path = PpsFoodFeed::META_DIR + "meta.json"
      File.write(path, JSON.pretty_generate(@h))
    end

    def to_h
      return @h.dup
    end
  end
end
