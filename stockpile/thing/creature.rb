module DFStock

  module CreatureQueries
    def is_creature? ; cache(:creature, creature_index) { raw.respond_to?(:creature_id) && !flags[:EQUIPMENT_WAGON] } end

    def is_stockpile_animal?
      cache(:stockpile_animal, creature_index) { is_creature? && raw.creature_id !~ /^(FORGOTTEN_BEAST|TITAN|DEMON|NIGHT_CREATURE)_/ }
    end

    def edible_cooked?  ; cache(:edible_cooked, creature_index) { material_flags[:EDIBLE_COOKED] } end
    def edible_raw?     ; cache(:edible_raw,    creature_index) { material_flags[:EDIBLE_RAW] } end
    def edible?         ; cache(:edible,        creature_index) { edible_cooked? || edible_raw? } end

    def lays_eggs?        ; cache(:eggs,    creature_index) { raw.caste.any? {|c| c.flags.to_hash[:LAYS_EGGS] } } end # Finds male and female of egg-laying species
    def grazer?           ; cache(:grazer,  creature_index) { raw.caste.any? {|c| c.flags.to_hash[:GRAZER] } } end
    def produces_honey?   ; cache(:honey,   creature_index) { materials.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } } end
    def provides_leather? ; cache(:leather, creature_index) { materials.any? {|mat| mat.id == 'LEATHER' } } end
  end

  # food/fish[0] = Cuttlefish(F) = raws.creatures.all[446 = raws.mat_table.organic_indexes[1 = :Fish][0]]
  # NOTE: Not all creatures are stockpilable, and not everything in the array is a creature
  # TODO: Derive Animals from this, and use this then non-sparse class to parent eggs.
  class Creature < Thing
    def self.creature_raws ; cache(:creatures) { df.world.raws.creatures.all } end
    def self.creature_indexes ; (0 ... creature_raws.length).to_a end
    def self.creatures ; creature_indexes.each_index.map {|i| Creature.new i } end
    # def self.index_translation ; creature_indexes end

    def self.find_creature_by_organic cat_name, index ; creature_index, caste_num = organic(cat_name, index) ; creature_raws[creature_index].caste[caste_num] ; end

    def self.find_creature_index raw ; creature_raws.index raw end

    def raw ; self.class.creature_raws[creature_index] end
    def flags ; raw.flags end
    # def token ; raw.creature_id end

    def caste_symbol
      {'QUEEN'   => '♀', 'FEMALE' => '♀', 'SOLDIER' => '♀', 'WORKER' => '♀',
       'KING'    => '♂',   'MALE' => '♂', 'DRONE' => '♂',
       'DEFAULT' => '?'
      }[caste.caste_id]
    end
    def caste_index ; @caste_index ||= 0 end
    def caste ; raw.caste[caste_index] end

    # def token ; "#{caste.caste_name.first}" end # 'toad *woman*' leather. Which caste is the default?
    def token ; raw.name.first end
    def to_s ; "#{super} creature_index=#{creature_index}" end

    attr_reader :creature_index
    def initialize index, link: nil, caste: nil
      @creature_index = index
      @caste_index = caste
      super index, link: link
    end
  end

  class Animal < Creature
    def self.animal_indexes ; cache(:animals) { creatures.each_with_index.inject([]) {|a,(c,i)| a << i if c.is_stockpile_animal? ; a } } end
    def self.animals ; animal_indexes.each_index.map {|i| Animal.new i } end
    # def self.index_translation ; animal_indexes end

    def creature_index ; self.class.animal_indexes[animal_index] end

    def to_s ; super + " animal_index=#{animal_index}" end
    def token ; n = raw.name[1] ; n =~ /[A-Z]/ ? n : n.capitalize end # Needs to match 'Toad Men' and 'Giant lynx' and 'Protected Helpers'

    attr_reader :animal_index
    def initialize index, link: nil
      @animal_index = index
      super creature_index, link: link
    end
  end

  # Meat indexes are materials, which then point to their animal
  class Meat < Creature
    def self.meat_category ; organic_category :Meat end
    def self.meat_types ; organic_types[meat_category] end
    def self.meat_indexes ; (0 ... meat_types.length).to_a end
    def self.meat_materials ; cache(:meat) { meat_types.map {|c,i| material_info c, i } } end
    def self.meats ; meat_indexes.each_index.map {|i| Meat.new i } end
    # def self.index_translation ; meat_indexes ; end

    def mat_index ; self.class.meat_types[meat_index].first end
    def mat_type  ; self.class.meat_types[meat_index].last end
    def material_info ; self.class.meat_materials[meat_index] end
    def material ; material_info.material end
    def raw ; material_info.mode == :Creature ? material_info.creature : material_info.plant end # NOTE: Not all meats are from animals.
    def token ; "#{material.prefix}#{" #{material.meat_name[2]}" if material.meat_name[2] && !material.meat_name[2].empty?} #{material.meat_name.first}" end
    def to_s ; "#{super} @meat_index=#{index}" end

    attr_reader :meat_index
    def initialize index, link: nil
      @meat_index = index
      super
    end
  end

  class Fish < Creature
    def self.fish_category ; organic_category :Fish end
    def self.fish_types ; organic_types[fish_category] end
    def self.fish_indexes ; (0 ... fish_types.length).to_a end
    def self.fish_raws ; cache(:fish) { fish_types.map {|i,c| creature_raws[i] } } end
    def self.fish ; fish_indexes.each_index.map {|i| Fish.new i } end
    # def self.index_translation ; fish_indexes ; end

    def types ; self.class.fish_types end
    def mat_index ; types[fish_index].first end
    def mat_type  ; types[fish_index].last end

    def creature_index ; self.class.find_creature_index self.class.fish_raws[fish_index] end
    def caste_index ; mat_type end
    def token ; title_case "#{caste.caste_name.first}, #{caste_symbol}" end
    def to_s ; "#{super} fish_index=#{fish_index}" end

    attr_reader :fish_index
    def initialize index, link: nil
      @fish_index = index
      super
    end
  end

  class UnpreparedFish < Creature # TODO: Try basing off Fish
    def self.unpreparedfish_category ; organic_category :UnpreparedFish end
    def self.unpreparedfish_types ; organic_types[unpreparedfish_category] end
    def self.unpreparedfish_indexes ; (0 ... unpreparedfish_types.length).to_a end
    def self.unpreparedfish_raws ; cache(:unpreparedfish) { unpreparedfish_types.map {|i,c| creature_raws[i] } } end
    def self.unpreparedfish ; unpreparedfish_indexes.each_index.map {|i| UnpreparedFish.new i } end
    # def self.index_translation ; unpreparedfish_indexes ; end

    def types ; self.class.unpreparedfish_types end
    def mat_index ; types[unpreparedfish_index].first end
    def mat_type  ; types[unpreparedfish_index].last end

    def creature_index ; self.class.find_creature_index self.class.unpreparedfish_raws[unpreparedfish_index] end
    def caste_index ; mat_type end
    def token ; title_case "#{caste.caste_name.first}, #{caste_symbol}" end
    def to_s ; "#{super} unpreparedfish_index=#{unpreparedfish_index}" end

    attr_reader :unpreparedfish_index
    def initialize index, link: nil
      @unpreparedfish_index = index
      super
    end
  end

  # Egg indexes are creatures, there is no one egg material
  class Egg < Creature
    def self.egg_category ; organic_category :Eggs end
    def self.egg_types ; organic_types[egg_category] end
    def self.egg_indexes ; (0 ... egg_types.length).to_a end
    def self.eggs ; egg_indexes.each_index.map {|i| Egg.new i } end
    # def self.index_translation ; egg_indexes end

    def creature_index ; self.class.egg_types[egg_index].first end
    def materials ; raw.material.select {|m| m.id =~ /EGG/ } end
    def material ; materials.find {|m| m.id =~ /YOLK/ } end

    def token ; (raw.caste.first.caste_name.first.split(/\s+/) + ['egg']).map(&:capitalize).join(' ') end
    def to_s ; super + " egg_index=#{egg_index}" end

    attr_reader :egg_index
    def index ; egg_index end
    def initialize index, link: nil
      @egg_index = index
      super creature_index, link: link # Passthrough
      @index = egg_index
    end
  end

  class CreatureDrink < Creature
    def self.creaturedrink_category ; organic_category :CreatureDrink end
    def self.creaturedrink_types ; organic_types[creaturedrink_category] end
    def self.creaturedrink_material_infos ; creaturedrink_types.map {|(c,i)| material_info c, i } end
    def self.creaturedrink_indexes ; (0 ... creaturedrink_types.length).to_a end
    def self.creaturedrinks ; creaturedrink_indexes.each_index.map {|i| CreatureDrink.new i } end
    # def self.index_translation ; creaturedrink_indexes end

    def material_info ; self.class.creaturedrink_material_infos[creaturedrink_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; "#{material.state_name[:Liquid]}" end
    def to_s ; super + " creaturedrink_index=#{creaturedrink_index}" end

    attr_reader :creaturedrink_index
    def initialize index, link: nil
      @creaturedrink_index = index
      super
    end
  end

  class CreatureCheese < Creature
    def self.creaturecheese_category ; organic_category :CreatureCheese end
    def self.creaturecheese_types ; organic_types[creaturecheese_category] end
    def self.creaturecheese_material_infos ; creaturecheese_types.map {|(c,i)| material_info c, i } end
    def self.creaturecheese_indexes ; (0 ... creaturecheese_types.length).to_a end
    def self.creaturecheeses ; creaturecheese_indexes.each_index.map {|i| CreatureCheese.new i } end
    # def self.index_translation ; creaturecheese_indexes end

    def material_info ; self.class.creaturecheese_material_infos[creaturecheese_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; "#{material.state_name[:Solid]}" end
    def to_s ; super + " creaturecheese_index=#{creaturecheese_index}" end

    attr_reader :creaturecheese_index
    def initialize index, link: nil
      @creaturecheese_index = index
      super
    end
  end

  class CreaturePowder < Creature # NOTE: Empty category
    def self.creaturepowder_category ; organic_category :CreaturePowder end
    def self.creaturepowder_types ; organic_types[creaturepowder_category] end
    def self.creaturepowder_material_infos ; creaturepowder_types.map {|(c,i)| material_info c, i } end
    def self.creaturepowder_indexes ; (0 ... creaturepowder_types.length).to_a end
    def self.creaturepowders ; creaturepowder_indexes.each_index.map {|i| CreaturePowder.new i } end
    # def self.index_translation ; creaturepowder_indexes end

    def material_info ; self.class.creaturepowder_material_infos[creaturepowder_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; "#{material.state_name[:Solid]}" end
    def to_s ; super + " creaturepowder_index=#{creaturepowder_index}" end

    attr_reader :creaturepowder_index
    def initialize index, link: nil
      @creaturepowder_index = index
      super
    end
  end

  class Silk < Creature # Note: Does not always have a raw, or a creature_index
    def self.silk_category ; organic_category :Silk end
    def self.silk_types ; organic_types[silk_category] end
    def self.silk_material_infos ; silk_types.map {|(c,i)| material_info c, i } end
    def self.silk_indexes ; (0 ... silk_types.length).to_a end
    def self.silks ; silk_indexes.each_index.map {|i| Silk.new i } end
    # def self.index_translation ; silk_indexes end

    def creature_index ; self.class.find_creature_index(raw) if raw end
    def material_info ; self.class.silk_material_infos[silk_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def mode ; material_info.mode end
    def raw ; mode == :Creature ? material_info.creature : material_info.inorganic end
    def token ; title_case(mode == :Creature ? "#{raw.name.first} Silk" : material.state_name[:Solid]) end
    def to_s ; super + " silk_index=#{silk_index}" end

    attr_reader :silk_index
    def initialize index, link: nil
      @silk_index = index
      super
    end
  end

  class Yarn < Creature
    def self.yarn_category ; organic_category :Yarn end
    def self.yarn_types ; organic_types[yarn_category] end
    def self.yarn_material_infos ; yarn_types.map {|(c,i)| material_info c, i } end
    def self.yarn_indexes ; (0 ... yarn_types.length).to_a end
    def self.yarns ; yarn_indexes.each_index.map {|i| Yarn.new i } end
    # def self.index_translation ; yarn_indexes end

    def creature_index ; self.class.find_creature_index(raw) if raw end
    def material_info ; self.class.yarn_material_infos[yarn_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; title_case "#{raw.name.first} #{material.state_name[:Solid]}" end
    def to_s ; super + " yarn_index=#{yarn_index}" end

    attr_reader :yarn_index
    def initialize index, link: nil
      @yarn_index = index
      super
    end
  end

  class MetalThread < Creature
    def self.metalthread_category ; organic_category :MetalThread end
    def self.metalthread_types ; organic_types[metalthread_category] end
    def self.metalthread_material_infos ; metalthread_types.map {|(c,i)| material_info c, i } end
    def self.metalthread_indexes ; (0 ... metalthread_types.length).to_a end
    def self.metalthreads ; metalthread_indexes.each_index.map {|i| MetalThread.new i } end
    # def self.index_translation ; metalthread_indexes end

    def creature_index ; self.class.find_creature_index(raw) if raw end
    def material_info ; self.class.metalthread_material_infos[metalthread_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.inorganic end
    def token ; title_case material.state_name[:Solid] end
    def to_s ; super + " metalthread_index=#{metalthread_index}" end

    attr_reader :metalthread_index
    def initialize index, link: nil
      @metalthread_index = index
      super
    end
  end

  class Fat < Creature
    def self.fat_category ; organic_category :Glob end
    def self.fat_types ; organic_types[fat_category] end
    def self.fat_material_infos ; cache(:fats) { fat_types.map {|(t,i)| material_info t, i } } end
    def self.fat_indexes ; (0 ... fat_types.length).to_a end
    def self.fats ; fat_indexes.each_index.map {|i| Fat.new i } end
    # def self.index_translation ; fat_indexes end

    def material_info ; self.class.fat_material_infos[fat_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; title_case "#{raw.name.first} #{material.id}" end
    def to_s ; super + " fat_index=#{fat_index}" end

    attr_reader :fat_index
    def initialize index, link: nil
      @fat_index = index
      super
    end
  end

  class CreatureExtract < Creature
    def self.creatureextract_category ; organic_category :CreatureLiquid end
    def self.creatureextract_types ; organic_types[creatureextract_category] end
    def self.creatureextract_material_infos ; cache(:creatureextracts) { creatureextract_types.map {|(c,i)| material_info c, i } } end
    def self.creatureextract_indexes ; (0 ... creatureextract_types.length).to_a end
    def self.creatureextracts ; creatureextract_indexes.each_index.map {|i| CreatureExtract.new i } end
    # def self.index_translation ; creatureextract_indexes end

    def material_info ; self.class.creatureextract_material_infos[creatureextract_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; super + " #{material.state_name[:Liquid]}" end
    def to_s ; super + " creatureextract_index=#{creatureextract_index}" end

    attr_reader :creatureextract_index
    def initialize index, link: nil
      @creatureextract_index = index
      super
    end
  end

  class Leather < Creature
    def self.leather_category ; organic_category :Leather end
    def self.leather_types ; organic_types[leather_category] end
    def self.leather_material_infos ; cache(:leathers) { leather_types.map {|(c,i)| material_info c, i } } end
    def self.leather_indexes ; (0 ... leather_types.length).to_a end
    def self.leathers ; leather_indexes.each_index.map {|i| Leather.new i } end
    # def self.index_translation ; leather_indexes end

    def material_info ; self.class.leather_material_infos[leather_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; title_case(super + " #{material.state_name[:Solid]}") end
    def to_s ; super + " leather_index=#{leather_index}" end

    attr_reader :leather_index
    def initialize index, link: nil
      @leather_index = index
      super
    end
  end

  class Parchment < Leather
    def self.parchment_types ; leather_types end
    def self.parchment_material_infos ; cache(:parchments) { parchment_types.map {|(c,i)| material_info c, i } } end
    def self.parchment_indexes ; (0 ... parchment_types.length).to_a end
    def self.parchments ; parchment_indexes.each_index.map {|i| Parchment.new i } end
    # def self.index_translation ; parchment_indexes end

    def material_info ; self.class.parchment_material_infos[parchment_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.creature end
    def token ; "#{raw.name.first.capitalize} Parchment Sheet" end
    def to_s ; super + " parchment_index=#{parchment_index}" end

    attr_reader :parchment_index
    def initialize index, link: nil
      @parchment_index = index
      super
    end
  end

end
