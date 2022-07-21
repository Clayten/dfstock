require 'thing'

module DFStock

  class Creature < Thing
    from_raws(:creature) { true }
    def caste ; raw.caste[@caste_index] if @caste_index end
    def token ; title_case (caste ? caste.caste_name.first : raw.name[1]) end
  end

  # The stockpile 'Animal' class, not all creatures
  class Animal < Thing
    from_raws(:creature) {|x| x.is_stockpile_animal? }
    def caste ; raw.caste[@caste_index] if @caste_index end
    # If the name is capitalized already, leave it. Otherwise, capitalize the first word. Needs to match 'Toad Men' and 'Giant lynx' and 'Protected Helpers'
    def token ; n = (caste ? caste.caste_name.first : raw.name[1]) ; n =~ /[A-Z]/ ? n : n.capitalize end
    def link_index ; creature_index end
  end

  class Meat < Thing
    from_category :Meat
    def caste ; raw.caste[@caste_index] if @caste_index end
    def token ; "#{(caste ? caste.caste_name.first : material.prefix)}#{" #{material.meat_name[2]}" if material.meat_name[2] && !material.meat_name[2].empty?} #{material.meat_name.first}" end
  end

  class Fish < Thing
    from_category :Fish
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| [*r.material].first } } end

    def materials ; raw.material end
    def caste_index ; self.class.types[index].last end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "#{caste.caste_name.first}, #{caste_symbol}" end
  end

  class UnpreparedFish < Thing
    from_category :UnpreparedFish
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| [*r.material].first } } end

    def materials ; raw.material end
    def caste_index ; self.class.types[index].last end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "Unprepared Raw #{caste.caste_name.first}, #{caste_symbol}" end
  end

  class Egg < Thing
    from_category :Eggs
    def self.infos ; end
    def self.raws      ; cache([:raws,      self]) { types.map {|creature_index, caste_index| raws_creature[creature_index] } } end
    def self.materials ; cache([:materials, self]) { raws.map {|r| r.material.find {|m| m.id =~  /YOLK/i } } } end

    def caste ; raw.caste.find {|c| c.flags[:LAYS_EGGS] } end
    def token ; title_case (caste.caste_name.first + ' egg') end
  end

  class CreatureDrink < Thing
    from_category :CreatureDrink
    def caste_index ; raw.caste.index {|c| c.caste_id == 'WORKER' } end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class CreatureCheese < Thing
    from_category :CreatureCheese
    def caste_index ; raw.caste.index {|c| c.caste_id == 'MILKABLE' } end
    def caste ; raw.caste[caste_index] end
    def token ; title_case "#{material.state_name[:Solid]}" end
  end

  class CreaturePowder < Thing
    from_category :CreaturePowder
    def token ; "#{material.state_name[:Solid]}" end
  end

  class Silk < Thing
    from_category :Silk
    def token ; title_case(raw.respond_to?(:name) ? "#{raw.name.first} Silk" : material.state_name[:Solid]) end
  end

  class Yarn < Thing
    from_category :Yarn
    def token ; title_case "#{raw.name.first} #{material.state_name[:Solid]}" end
  end

  class Fat < Thing
    from_category :Glob
    def token ; "#{raw.name.first} #{material.id.downcase}" end
  end

  class CreatureExtract < Thing
    from_category :CreatureLiquid
    def token ; title_case "#{material.prefix} #{material.state_name[:Liquid]}".strip end
  end

  class Leather < Thing
    from_category :Leather
    def token ; title_case("#{raw.name.first} #{material.state_name[:Solid]}") end
  end

  class Parchment < Thing
    from_category :Parchment
    def token ; title_case("#{raw.name.first} #{material.state_name[:Solid]} Sheet") end
  end
end
