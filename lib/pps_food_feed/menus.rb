# frozen_string_literal: true

require_relative "menu"

class PpsFoodFeed
  module Menus
    def self.get(name)
      return MENU_MAP.fetch(name, DEFAULT)
    end

    BREAKFAST_LUNCH = PpsFoodFeed::Menu.new(["breakfast", "lunch"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains two rows.
      If it contains two rows, the top row is breakfast for that day, the bottom row is lunch for that day.
    TXT
    BREAKFAST_LUNCH_SNACK = PpsFoodFeed::Menu.new(["breakfast", "lunch", "snack"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains three rows.
      If it contains three rows, the top row is breakfast for that day, the middle row is lunch for that day, the bottom row is snack for that day.
    TXT
    DEFAULT = PpsFoodFeed::Menu.new(["meal"], <<~TXT)
      The cell for each day contains text including 'Schools Closed' or 'No School for Students', or it contains the meal for that day.
      The meal may span multiple lines, or include multiple items, such as "Burrito Bar" and "Pizza" for the same day.
      In this case, the meal should be output as "Burrito Bar, Pizza".
    TXT

    MENU_MAP = {
      "Breakfast, Lunch (Access, CTP)" => BREAKFAST_LUNCH,
      "Early Learners" => BREAKFAST_LUNCH_SNACK,
      "Head Start (Creston)" => BREAKFAST_LUNCH_SNACK,
      "Head Start (MECP)" => BREAKFAST_LUNCH_SNACK,
      "Head Start, Pre-K" => BREAKFAST_LUNCH_SNACK,
      "MECP" => BREAKFAST_LUNCH_SNACK,
      "Neighborhood House" => BREAKFAST_LUNCH,
    }.freeze
  end
end
