require 'thing2'

module DFStock

  class Creature2 < Thing2
    from_raws(:creature) { true }
    def token ; title_case raw.name[1] end
  end

  # The stockpile 'Animal' class, not all creatures
  class Animal2 < Thing2
    from_raws(:creature) {|x| x.is_stockpile_animal? }
    def token ; n = raw.name[1] ; n =~ /[A-Z]/ ? n : n.capitalize end # Needs to match 'Toad Men' and 'Giant lynx' and 'Protected Helpers'
    def link_index ; creature2_index end
  end

  class Meat2 < Thing2
    from_category :Meat
    def token ; "#{material.prefix}#{" #{material.meat_name[2]}" if material.meat_name[2] && !material.meat_name[2].empty?} #{material.meat_name.first}" end
  end

  class Fish2 < Thing2
    from_category :Fish
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| [*r.material].first } } end

    def caste_index ; self.class.types[index].last end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "#{caste.caste_name.first}, #{caste_symbol}" end
  end

  class UnpreparedFish2 < Thing2
    from_category :UnpreparedFish
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| [*r.material].first } } end

    def caste_index ; self.class.types[index].last end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "Unprepared Raw #{caste.caste_name.first}, #{caste_symbol}" end
  end

  class Egg2 < Thing2
    from_category :Eggs
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| r.material.find {|m| m.id =~  /YOLK/i } } } end

    def caste ; raw.caste.find {|c| c.flags[:LAYS_EGGS] } end
    def token ; title_case (caste.caste_name.first.split(/\s+/) + ['egg']).join(' ') end
  end

  class CreatureDrink2 < Thing2
    from_category :CreatureDrink
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class CreatureCheese2 < Thing2
    from_category :CreatureCheese
    def token ; title_case "#{material.state_name[:Solid]}" end
  end

  class CreaturePowder2 < Thing2
    from_category :CreaturePowder
    def token ; "#{material.state_name[:Solid]}" end
  end

  class Silk2 < Thing2
    from_category :Silk
    def token ; title_case(raw.respond_to?(:name) ? "#{raw.name.first} Silk" : material.state_name[:Solid]) end
  end

  class Yarn2 < Thing2
    from_category :Yarn
    def token ; title_case "#{raw.name.first} #{material.state_name[:Solid]}" end
  end

  class Fat2 < Thing2
    from_category :Glob
    def token ; "#{raw.name.first} #{material.id.downcase}" end
  end

  class CreatureExtract2 < Thing2
    from_category :CreatureLiquid
    def token ; title_case "#{material.prefix} #{material.state_name[:Liquid]}".strip end
  end

  class Leather2 < Thing2
    from_category :Leather
    def token ; title_case("#{raw.name.first} #{material.state_name[:Solid]}") end
  end

  class Parchment2 < Thing2
    from_category :Parchment
    def token ; title_case("#{raw.name.first} #{material.state_name[:Solid]} Sheet") end
  end
end
