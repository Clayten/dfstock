require 'thing2'

module DFStock
  class Creature2 < Thing2
  end

  class Plant2 < Thing2
    organic_category :Plants

    def raw       ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_infos")[idx].plant end
    def material  ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_infos")[idx].material end
    def materials ; raw.material end

    # plant methods that should be on Thing
    def growths   ; has_raw? && raw.growths end
    def growth    ; growths.find {|g| g.str_growth_item.include? material.id } end

    def token ; title_case raw.name end

    def link_index ; index end
  end

  class FruitLeaf2 < Plant2
    organic_category :Leaf
    def token ; title_case "#{growth.name}" end
  end

  class PlantPowder2 < Plant2
    organic_category :PlantPowder
    def token ; title_case material.state_name[:Powder] end
  end

  class Seed2 < Plant2
    organic_category :Seed
    def token ; title_case raw.seed_plural end
  end

end



