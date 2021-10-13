module DFStock

  module PlantQueries
    def mat_mill       ; materials.find {|m| m.id == 'MILL' } end
    def mat_drink      ; materials.find {|m| m.id == 'DRINK' } end
    def mat_wood       ; materials.find {|m| m.id == 'WOOD' } end
    def mat_seed       ; materials.find {|m| m.id == 'SEED' } end
    def mat_leaf       ; materials.find {|m| m.id == 'LEAF' } end
    def mat_thread     ; materials.find {|m| m.id == 'THREAD' } end
    def mat_structural ; materials.find {|m| m.id == 'STRUCTURAL' } end

    def mill?       ; !!mat_mill end
    def drink?      ; !!mat_drink end
    def wood?       ; !!mat_wood end
    def seed?       ; !!mat_seed end
    def leaf?       ; !!mat_leaf end
    def thread?     ; !!mat_thread end
    def structural? ; !!mat_structural end

    def edible_cooked?  ; material_flags[:EDIBLE_COOKED] end
    def edible_raw?     ; material_flags[:EDIBLE_RAW] end
    def edible?         ; edible_cooked? || edible_raw? end
    def brewable?       ; material_flags[:ALCOHOL_PLANT] && !%w(DRINK SEED MILL).include?(material.id) end
    def millable?       ; mill? end

    def tree? ; raw.flags[:TREE] end

    def subterranean? ; flags.to_hash.select {|k,v| v }.any? {|f| f =~ /BIOME_SUBTERRANEAN/ } end
    def above_ground? ; !subterranean end

    def growths ; raw.growths end
    def growth_ids ; growths.map(&:id) end
    def grows_fruit? ; growth_ids.include? 'FRUIT' end
    def grows_bud?   ; growth_ids.include? 'BUD' end
    def grows_leaf?  ; growth_ids.include? 'LEAVES' end # FIXME: Does this mean edible leaf? Add another check?

    def winter? ; raw.flags[:WINTER] end
    def spring? ; raw.flags[:SPRING] end
    def summer? ; raw.flags[:SUMMER] end
    def autumn? ; raw.flags[:AUTUMN] end
    def crop? ; winter? || spring? || summer? || autumn? end
  end

  class Plant < Thing
    def self.plant_category ; organic_category :Plants end
    def self.plant_raws ; df.world.raws.plants.all end
    def self.plant_types ; organic_types[plant_category] end
    def self.plant_material_infos ; plant_types.map {|(c,i)| material_info c, i } end
    def self.plants ; plant_indexes.each_index.map {|i| Plant.new i } end
    def self.plant_indexes ; (0 ... plant_types.length).to_a end
    # def self.index_translation ; plant_indexes end

    def self.find_plant_index raw ; plant_raws.index raw end

    def raw ; self.class.plant_raws[plant_index] end
    def token ; raw.name end
    def to_s ; super + " plant_index=#{plant_index}" end

    attr_reader :plant_index
    def initialize index, link: nil
      @plant_index = index
      super
    end
  end

  class PlantProduct < Plant
    def self.plantproduct_indexes ; cache(:plantproducts) { plants.each_with_index.inject([]) {|a,(x,i)| a << i if x.crop? ; a } } end
    def self.plantproducts ; plantproduct_indexes.each_index.map {|i| PlantProduct.new i } end
    # def self.index_translation ; plantproduct_indexes end

    def plant_index ; self.class.plantproduct_indexes[plantproduct_index] end
    def to_s ; super + " plantproduct_index=#{plantproduct_index}" end

    attr_reader :plantproduct_index
    def initialize index, link: nil
      @plantproduct_index = index
      super plant_index, link: link
    end
  end

  class PlantDrink < Plant
    def self.plantdrink_category ; organic_category :PlantDrink end
    def self.plantdrink_types ; organic_types[plantdrink_category] end
    def self.plantdrink_material_infos ; plantdrink_types.map {|(c,i)| material_info c, i } end
    def self.plantdrink_indexes ; (0 ... plantdrink_types.length).to_a end
    def self.plantdrinks ; plantdrink_indexes.each_index.map {|i| PlantDrink.new i } end
    # def self.index_translation ; plantdrink_indexes end

    def material_info ; self.class.plantdrink_material_infos[plantdrink_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; "#{material.state_name[:Liquid]}" end
    def to_s ; super + " plantdrink_index=#{plantdrink_index}" end

    attr_reader :plantdrink_index
    def initialize index, link: nil
      @plantdrink_index = index
      super
    end
  end

  class PlantCheese < Plant # NOTE: Empty category
    def self.plantcheese_category ; organic_category :PlantCheese end
    def self.plantcheese_types ; organic_types[plantcheese_category] end
    def self.plantcheese_material_infos ; plantcheese_types.map {|(c,i)| material_info c, i } end
    def self.plantcheese_indexes ; (0 ... plantcheese_types.length).to_a end
    def self.plantcheeses ; plantcheese_indexes.each_index.map {|i| PlantCheese.new i } end
    # def self.index_translation ; plantcheese_indexes end

    def material_info ; self.class.plantcheese_material_infos[plantcheese_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; "#{material.state_name[:Liquid]}" end
    def to_s ; super + " plantcheese_index=#{plantcheese_index}" end

    attr_reader :plantcheese_index
    def initialize index, link: nil
      @plantcheese_index = index
      super
    end
  end

  class PlantPowder < Plant
    def self.plantpowder_category ; organic_category :PlantPowder end
    def self.plantpowder_types ; organic_types[plantpowder_category] end
    def self.plantpowder_material_infos ; plantpowder_types.map {|(c,i)| material_info c, i } end
    def self.plantpowder_indexes ; (0 ... plantpowder_types.length).to_a end
    def self.plantpowders ; plantpowder_indexes.each_index.map {|i| PlantPowder.new i } end

    # def self.plantpowder_indexes ; cache(:plantpowders) { plants.each_with_index.inject([]) {|a,(x,i)| a << i if x.mill? ; a } } end
    # def self.plantpowders ; plantpowder_indexes.each_index.map {|i| PlantPowder.new i } end
    # def self.index_translation ; plantpowder_indexes end

    def plant_index ; self.class.plantpowder_indexes[plantpowder_index] end
    def to_s ; super + " plantpowder_index=#{plantpowder_index}" end

    attr_reader :plantpowder_index
    def initialize index, link: nil
      @plantpowder_index = index
      super
    end
  end

  # NOTE: Plants can be in here multiple times, ex Caper -> caper fruit, caper, caper berry.
  # NOTE: Index is fruitleaf_index, not a sparse index into plants
  class FruitLeaf < Plant
    def self.fruitleaf_category ; organic_category :Leaf end
    def self.fruitleaf_types ; organic_types[fruitleaf_category] end
    def self.fruitleaf_material_infos ; fruitleaf_types.map {|(t,i)| material_info t, i } end
    def self.fruitleaf_indexes ; fruitleaf_material_infos.map {|mi| find_plant_index mi.plant } end
    def self.fruitleaves ; fruitleaf_indexes.map {|i| FruitLeaf.new i } end
    # def self.index_translation ; fruitleaf_indexes end

    def self.fruitleaf_growths

    end

    def plant_index ; self.class.fruitleaf_indexes[fruitleaf_index] end
    def to_s ; super + " fruitleaf_index=#{fruitleaf_index}" end
    def raw ; material_info.plant end
    def material_info ; self.class.fruitleaf_material_infos[fruitleaf_index] end
    def material ; material_info.material end
    def materials ; [material] end
    def growth ; self.class.fruitleaf_growths[fruitleaf_index] end # This plant might have two or more growths - find the correct one
    def token ; title_case "#{raw.name} #{material.id}" end
    attr_reader :fruitleaf_index
    def initialize index, link: nil
      @fruitleaf_index = index
      super
    end
  end

  # NOTE: Index is seed_index, not a sparse index into plants
  class Seed < Plant
    def self.seed_indexes ; cache(:seeds) { plants.each_with_index.inject([]) {|a,(t,i)| a << i if t.seed? ; a } } end
    def self.seeds ; seed_indexes.each_index.map {|i| Seed.new i } end
    # def self.index_translation ; seed_indexes end

    def material ; mat_seed end
    def plant_index ; self.class.seed_indexes[seed_index] end
    def index ; seed_index end
    def to_s ; super + " seed_index=#{seed_index}" end

    attr_reader :seed_index
    def initialize index, link: nil
      @seed_index = index
      super self.class.index_translation[index], link: link # Passthrough - different number than parent class
    end
  end

  class Paste < Plant
    def self.paste_category ; organic_category :Paste end
    def self.paste_types ; organic_types[paste_category] end
    def self.paste_material_infos ; paste_types.map {|(c,i)| material_info c, i } end
    def self.paste_indexes ; paste_material_infos.map {|mi| find_plant_index mi.plant } end
    def self.pastes ; paste_indexes.each_index.map {|i| Paste.new i } end
    # def self.index_translation ; paste_indexes end

    def plant_index ; self.class.paste_indexes[paste_index] end
    def material_info ; self.class.paste_material_infos[paste_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; "#{material.state_name[:Paste]}" end
    def to_s ; super + " paste_index=#{paste_index}" end

    attr_reader :paste_index
    def initialize index, link: nil
      @paste_index = index
      super
    end
  end

  class PlantFiber < Plant
    def self.plantfiber_category ; organic_category :PlantFiber end
    def self.plantfiber_types ; organic_types[plantfiber_category] end
    def self.plantfiber_material_infos ; plantfiber_types.map {|(c,i)| material_info c, i } end
    def self.plantfiber_indexes ; plantfiber_material_infos.map {|mi| find_plant_index mi.plant } end
    def self.plantfibers ; plantfiber_indexes.each_index.map {|i| PlantFiber.new i } end
    # def self.index_translation ; plantfiber_indexes end

    def plant_index ; self.class.plantfiber_indexes[plantfiber_index] end
    def material_info ; self.class.plantfiber_material_infos[plantfiber_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; title_case material.state_name[:Solid] end
    def to_s ; super + " plantfiber_index=#{plantfiber_index}" end

    attr_reader :plantfiber_index
    def initialize index, link: nil
      @plantfiber_index = index
      super
    end
  end

  # NOTE: Can't use PlantFiber because that doesn't contain papyrus
  class Paper < Plant
    def self.paper_types
      plant_base = 419
      plant_raws.each_with_index.map {|plant, plant_index|
        mat_index = plant.material.index {|m| m.reaction_class.any? {|rc| rc =~ /PAPER/ } }
        next unless mat_index
        [(plant_base + mat_index), plant_index]
      }.compact
    end
    def self.paper_material_infos ; paper_types.map {|(c,i)| material_info c, i } end
    def self.paper_indexes ; paper_material_infos.map {|mi| find_plant_index mi.plant } end
    def self.papers ; paper_indexes.each_index.map {|i| Paper.new i } end
    # def self.index_translation ; paper_indexes end

    def plant_index ; self.class.paper_indexes[paper_index] end
    def material_info ; self.class.paper_material_infos[paper_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; title_case "#{material.state_name[:Solid]} Sheet" end
    def to_s ; super + " paper_index=#{paper_index}" end

    attr_reader :paper_index
    def initialize index, link: nil
      @paper_index = index
      super
    end
  end

  class Pressed < Plant # FIXME: This needs to descend from Plant and Creature
    def self.pressed_category ; organic_category :Pressed end
    def self.pressed_types ; organic_types[pressed_category] end
    def self.pressed_material_infos ; pressed_types.map {|(c,i)| material_info c, i } end
    def self.pressed_indexes ; (0 ... pressed_types.length).to_a end
    def self.presseds ; pressed_indexes.each_index.map {|i| Pressed.new i } end
    # def self.index_translation ; pressed_indexes end

    def material_info ; self.class.pressed_material_infos[pressed_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.mode == :Plant ? material_info.plant : material_info.creature end # Not all pressings are plants
    def token ; "#{material.state_name[:Pressed]}" end
    def to_s ; super + " pressed_index=#{pressed_index}" end

    attr_reader :pressed_index
    def initialize index, link: nil
      @pressed_index = index
      super
    end
  end

  class PlantExtract < Plant
    def self.plantextract_category ; organic_category :PlantLiquid end
    def self.plantextract_types ; organic_types[plantextract_category] end
    def self.plantextract_material_infos ; plantextract_types.map {|(c,i)| material_info c, i } end
    def self.plantextract_indexes ; (0 ... plantextract_types.length).to_a end
    def self.plantextracts ; plantextract_indexes.each_index.map {|i| PlantExtract.new i } end
    # def self.index_translation ; plantextract_indexes end

    def material_info ; self.class.plantextract_material_infos[plantextract_index] end
    def material ; material_info.material end
    def material_flags ; material.flags end # Only look at this material
    def raw ; material_info.plant end
    def token ; "#{material.state_name[:Liquid]}" end
    def to_s ; super + " plantextract_index=#{plantextract_index}" end

    attr_reader :plantextract_index
    def initialize index, link: nil
      @plantextract_index = index
      super
    end
  end

  # There are two trees in the stockpile list, Abaca and Banana, that don't produce wood. Watch for nulls if sorting, etc.
  class Tree < Plant
    def self.tree_indexes ; cache(:trees) { plants.each_with_index.inject([]) {|a,(t,i)| a << i if t.tree? ; a } } end
    # def self.trees ; plants.select {|t| t.tree? } end
    def self.trees ; tree_indexes.length.times.map {|i| new i } end
    def self.woods ; trees.select {|t| t.wood? } end # Just the wood-producing trees
    # def self.index_translation ; tree_indexes end
    def plant_index ; self.class.tree_indexes[tree_index] end
    def to_s ; super + " tree_index=#{tree_index}" end

    def wood ; materials.find {|m| m.id == 'WOOD' } end
    def material_structural ; materials.find {|m| m.id == 'STRUCTURAL' } end

    def material ; wood || material_structural || materials.first end

    def value   ; wood.material_value if wood end
    def color   ; wood.build_color if wood end
    def density ; wood.solid_density if wood end

    attr_reader :tree_index
    def initialize index, link: nil
      @tree_index = index
      super plant_index, link: link
    end
  end

end
