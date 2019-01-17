module DFStock
  module Scaffold
    # This runs at inclusion into the FooMod classes
    def self.extended klass
      # p [:ext, klass]
      klass.instance_variable_set(:@features, []) # Initialize the array, eliminate old definitions from previous loads
    end

    # This runs during class-definition at load-time
    def add_array stockklass, desired_name, actual_name = desired_name
      desired_name, actual_name = desired_name.to_sym, actual_name
      array = [:array, desired_name, actual_name, stockklass]
      # p [:add_array, array]
      @features.delete_if {|kl, dn, an, sk| self == kl && desired_name == dn && actual_name == an && stockklass = sk }
      @features.push(array)
      desired_name
    end

    def add_flag desired_name, actual_name = desired_name
      flag = [:flag, desired_name, actual_name]
      @features.delete_if {|kl, dn, an, sk| self == kl && desired_name == dn && actual_name == an }
      @features.push(flag)
      desired_name
    end

    # This runs slightly later, at inclusion
    def included klass
      p [:included, self, klass, :features, @features.length]

      # FIXME Change add method to take class as an argument, not hidden in a block
      # then query the class's index_translation table for size, rather than the
      # base array of flags.
      @features.each {|type, desired_name, actual_name, stockklass|
        if :flag == type
          next if desired_name == actual_name # no-op
          klass.class_eval "alias #{desired_name} #{actual_name}" unless klass.method_defined?(desired_name)
        elsif :array == type
          if desired_name == actual_name
            original_name = "original_#{desired_name}"
            if !method_defined? original_name
              klass.class_eval "alias #{original_name} #{actual_name}" unless klass.method_defined?(original_name)
              klass.class_eval { undef_method actual_name }
            end
          end

          flags_array_name = original_name || actual_name
          # p [:stockklass, stockklass, (stockklass.index_translation if stockklass.respond_to?(:index_translation))]
          klass.send(:define_method, desired_name) {|&b|
            flags_array = send flags_array_name
            list = stockklass.respond_to?(:index_translation) ? stockklass.index_translation : (0...stockklass.link.length)
            stockklass.index_translation.each_with_index.map {|v,idx|
              obj = begin
                stockklass.new idx, link: flags_array
              rescue ArgumentError
                p [:Rescued, idx]
                next
              end
            }.compact
          }
        else
          raise "Unknown type #{type}"
        end
      }
    end
  end
end

# A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
# mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
# A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
# As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.
module DFStock
  module Raw
    def raw_mod ; end
  end

  module Material
    def material_mod ; end
  end

  module PlantMaterial
    include Material
    def plant_mod ; end
  end

  class Thing
    include Material
    include Raw

    def self.find_material_info id, cat ; df::MaterialInfo.new cat, id end
    def self.find_material id, cat = 0 ; find_material_info(cat, id).material end # FIXME How to create the material directly?

    # (34, :fish) ->
    def self.find_organic cat_index, cat_name
      cat_num = DFHack::OrganicMatCategory::NUME[cat_name]
      raise "Unknown category '#{cat_name}'" unless cat_num
      mat_type  = df.world.raws.mat_table.organic_types[  cat_num][cat_index]
      mat_index = df.world.raws.mat_table.organic_indexes[cat_num][cat_index]
      # p [:f_o, cat_index, cat_name, cat_num, mat_type, mat_index]
      find_material_info mat_type, mat_index
    end
    def  enabled? ; raise unless link ; link[index] end
    def  enable   ; raise unless link ; link[index] = true  end
    def disable   ; raise unless link ; link[index] = false end
    def  toggle   ; raise unless link ; set !enabled? end
    def set   x   ; raise unless link ; x ? enable : disable end

    # Cache lookups - this is pretty important for performance
    def self.cache *name, &b
      name = name.first if name.length == 1
      cache_id ||= [self, name]
      return @@cache[cache_id] if @@cache.include?(cache_id)
      @@cache[cache_id] = yield
    end
    def cache *name, &b
      name = name.first if name.length == 1
      cache_id = [self.class, index, name]
      return @@cache[cache_id] if @@cache.include?(cache_id)
      @@cache[cache_id] = yield
    end

    def token ; 'NONE' end
    # def to_s ; "#{self.class.name}:#{'0x%016x' % object_id } linked=#{!!link} enabled=#{!!enabled?} token=#{token} index=#{index}" end
    def to_s ; "#{self.class.name} linked=#{!!link} enabled=#{!!enabled?} token=#{token} index=#{index}" end
    def inspect ; "#<#{to_s}>" rescue super end

    attr_reader :index, :link
    def initialize index, link: nil
      @index = index # The index into the 'link'ed array for the thing
      raise "No index provided" unless index
      @link     = link
      @@cache ||= {}
    end
  end

  class Inorganic < Thing
    def self.inorganics
      df.world.raws.inorganics
    end

    def self.token index
      inorganics[index].id
    end

    def raw ; self.class.inorganics[index] end

    def material ; raw.material end

    def token ; self.class.token index end

    def initialize index, link: nil
      super
    end
  end

  class Metal < Inorganic
    def self.index_translation ; table ||= inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if is_metal? s ; a } end

    def self.is_metal? inorganic
      inorganic.material.flags[:IS_METAL]
    end

    def inorganic_index ; self.class.index_translation[metal_index] end
    def to_s ; super + " metal_index=#{metal_index}" end

    attr_reader :metal_index
    def initialize index, link: nil
      @metal_index = index
      super inorganic_index, link: link
    end
  end

  class Stone < Inorganic
    def self.index_translation ; @table ||= ObjectSpace.each_object.select {|x| next unless x.is_a? Class ; x < self }.map(&:index_translation).flatten.sort end

    def self.is_ore? inorganic
      inorganic.flags[:METAL_ORE]
    end

    def self.is_economic? inorganic
      !inorganic.economic_uses.empty? &&
      !inorganic.flags[:METAL_ORE] &&
      !inorganic.flags[:SOIL] &&
      !inorganic.material.flags[:IS_METAL]
    end

    def self.is_clay? inorganic
       inorganic.id =~ /clay/i &&
      !inorganic.flags[:AQUIFER] &&
      !inorganic.material.flags[:IS_STONE]
    end

    def self.is_other? inorganic
       inorganic.material.flags[:IS_STONE] &&
      !inorganic.material.flags[:NO_STONE_STOCKPILE] &&
      !is_ore?(inorganic) &&
      !is_economic?(inorganic) &&
      !is_clay?(inorganic)
    end

    def initialize index, link: nil
      super
    end
  end

  class Ore < Stone
    def self.index_translation ; @table ||= inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if is_ore? s ; a } end
    def inorganic_index ; self.class.index_translation[ore_index] end
    def to_s ; super + " ore_index=#{ore_index}" end

    attr_reader :ore_index
    def initialize index, link: nil
      @ore_index = index
      super inorganic_index, link: link
    end
  end

  class EconomicStone < Stone
    def self.index_translation ; @table ||= inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if is_economic? s ; a } end
    def inorganic_index ; self.class.index_translation[economic_index] end
    def to_s ; super + " economic_index=#{economic_index}" end

    attr_reader :economic_index
    def initialize index, link: nil
      @economic_index = index
      super inorganic_index, link: link
    end
  end

  class OtherStone < Stone
    def self.index_translation ; @table ||= inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if is_other? s ; a } end
    def inorganic_index ; self.class.index_translation[other_index] end
    def to_s ; super + " other_index=#{other_index}" end

    attr_reader :other_index
    def initialize index, link: nil
      @other_index = index
      super inorganic_index, link: link
    end
  end

  class Clay < Stone
    def self.index_translation ; @table ||= inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if is_clay? s ; a } end
    def inorganic_index ; self.class.index_translation[clay_index] end
    def to_s ; super + " clay_index=#{clay_index}" end

    attr_reader :clay_index
    def initialize index, link: nil
      @clay_index = index
      super inorganic_index, link: link
    end
  end

  # food/fish[0] = Cuttlefish(F) = raws.creatures.all[446 = raws.mat_table.organic_indexes[1 = :Fish][0]]

  class Creature < Thing
    def self.find_creature id ; cache(:creature, id) { df.world.raws.creatures.all[id] } end

    def edible?           ; true end # What won't they eat? Lol! FIXME?
    def lays_eggs?        ; cache(:eggs   ) { creature.caste.any? {|c| c.flags.to_hash[:LAYS_EGGS] } } end # Finds male and female of egg-laying species
    def grazer?           ; cache(:grazer ) { creature.caste.any? {|c| c.flags.to_hash[:GRAZER] } } end
    def produces_honey?   ; cache(:honey  ) { creature.material.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } } end
    def provides_leather? ; cache(:leather) { creature.material.any? {|mat| mat.id == 'LEATHER' } } end

    def token ; creature.creature_id end
    def to_s ; "#{super} @creature_idx=#{creature_idx} @caste_id=#{caste_id}" end

    attr_reader :caste_id, :creature, :caste
    def initialize index, link: nil
      super
      @creature_idx = index
      @caste_id = caste_id || 0
      @creature = self.class.find_creature id
      raise RuntimeError, "Unknown creature idx: #{idx}" unless creature
      @caste    = creature.caste[caste_id]
    end
  end

#   class Material < Thing
#
#     def stone? ; flags.to_hash[:IS_STONE] end
#     # def produces_honey?   ; cache(:honey  ) { creature.material.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } } end
#
#     def color ; material.color end
#
#     def token ; @material.id end
#     def to_s ; "#{super} @material_type=#{material_type} @material_idx=#{material_idx}" end
#
#     attr_reader :material
#     def initialize id, link: nil
#       super id, link: link
#       @material = self.class.find_material_info id, 0
#       raise RuntimeError, "Unknown material id: #{id}" unless material
#     end
#   end
#
#   class Stone < Material
#     def self.find_stone id ; id end
#
#     def color ; stone.color end
#
#     def token ; @stone.id end
#     def to_s ; "#{super} @stone_id=#{id}" end
#
#     alias stone material
#     def initialize id, link: nil
#       super id, link: link
#       raise RuntimeError, "Unknown stone id: #{id}" unless stone && stone.stone?
#     end
#   end
#
#
#   class Metal < Material
#     def self.find_metal id ; id end
#
#     def token ; @metal end
#     def to_s ; "#{super} @metal_id=#{id}" end
#
#     attr_reader :metal
#     def initialize id, link: nil
#       super id, link: link
#       @metal = self.class.find_metal id
#       raise RuntimeError, "Unknown metal id: #{id}" unless metal
#     end
#   end
#
#
#   class Fish < Thing
#     def self.find_fish id ; find_organic id, :Fish end
#
#     def token ; @fish end
#     def to_s ; "#{super} @fish_id=#{id}" end
#
#     attr_reader :fish
#     def initialize id, link: nil
#       super
#       @fish = self.class.find_fish id
#       raise RuntimeError, "Unknown fish id: #{id}" unless fish
#     end
#   end
#
#
#   class Meat < Thing
#     def self.find_meat id ; find_organic id, :Meat end
#
#     def token ; @meat end
#     def to_s ; "#{super} @meat_id=#{id}" end
#
#     attr_reader :meat
#     def initialize id, link: nil
#       super id, link: link
#       @meat = self.class.find_meat id
#       raise RuntimeError, "Unknown meat id: #{id}" unless meat
#     end
#   end
#
#
#   class Furniture < Thing
#     def self.find_furniture id ; DFHack::FurnitureType::ENUM[id] end
#
#     def token ; @furniture end
#     def to_s ; "#{super} @furniture_id=#{id}" end
#
#     attr_reader :furniture
#     def initialize id, link: nil
#       super id, link: link
#       @furniture = self.class.find_furniture id
#       raise RuntimeError, "Unknown furniture id: #{id}" unless furniture
#     end
#   end
#
#   class PlantRaw < Thing
#     def self.find_plant id ; df.world.raws.plants.all[id] end
#
#     def flags ; plant.flags end
#
#     def tree? ; flags.to_hash[:TREE] end
#
#     def color ; plant.material[0].basic_color end
#     def build_color ; plant.material[0].build_color end
#     # def density ; plant.material[0].solid_density end
#
#     def materials      ; plant.material end
#
#     def food_mat_indexes
#       Hash[materials.map {|m|
#         idxs = m.food_mat_index.to_hash.select {|k,v| v != -1 }
#         [m.id, idxs]
#       }]
#     end
#
#     def material_ids   ; materials.map &:id end
#
#     def mill?       ; material_ids.include? 'MILL' end
#     def drink?      ; material_ids.include? 'DRINK' end
#     def wood?       ; material_ids.include? 'WOOD' end
#     def seed?       ; material_ids.include? 'SEED' end
#     def leaf?       ; material_ids.include? 'LEAF' end
#     def thread?     ; material_ids.include? 'THREAD' end
#     def structural? ; material_ids.include? 'STRUCTURAL' end
#
#     def mat_mill       ; material_ids.find {|id| id == 'MILL' } end
#     def mat_drink      ; material_ids.find {|id| id == 'DRINK' } end
#     def mat_wood       ; material_ids.find {|id| id == 'WOOD' } end
#     def mat_seed       ; material_ids.find {|id| id == 'SEED' } end
#     def mat_leaf       ; material_ids.find {|id| id == 'LEAF' } end
#     def mat_thread     ; material_ids.find {|id| id == 'THREAD' } end
#     def mat_structural ; material_ids.find {|id| id == 'STRUCTURAL' } end
#
#     def material_flags ; Hash[materials.inject({}) {|a,b| a.merge Hash[b.flags.to_hash.select {|k,v| v }] }.sort_by {|k,v| k.to_s }] end
#
#     def edible_cooked?  ; material_flags[:EDIBLE_COOKED] end
#     def edible_raw?     ; material_flags[:EDIBLE_RAW] end
#     def edible?         ; edible_cooked? || edible_raw? end
#     def brewable?       ; material_flags[:ALCOHOL_PLANT] end
#
#     def millable?       ; !!mat_thread end
#
#     def subterranean? ; flags.to_hash.select {|k,v| v }.any? {|f| f =~ /BIOME_SUBTERRANEAN/ } end
#     def above_ground? ; !subterranean end
#
#     def token ; plant.id end
#     def to_s ; "#{super} @plant_id=#{id}" end
#
#     attr_reader :plant
#     def initialize id, link: nil
#       super id, link: link
#       @plant = self.class.find_plant id
#       raise RuntimeError, "Unknown plant id: #{id}" unless plant
#     end
#   end
#
#   class Plant < PlantRaw
#     def initialize *a
#       super
#       raise ArgumentError, "Unknown food-plant id: #{id}" unless plant && food_plant?
#     end
#   end
#
#   class Seed < PlantRaw
#     def initialize *a
#       super
#       raise ArgumentError, "Unknown seed id: #{id}" unless plant && seed?
#     end
#   end
#
#   class Leaf < PlantRaw
#     def initialize *a
#       super
#       raise ArgumentError, "Unknown leaf id: #{id}" unless plant && leaf?
#     end
#   end
#
#   # Really "Tree", because the list include non-wood bearing trees.
#   class Wood < PlantRaw # FIXME rename Tree, call the field wood
#     def mat_wood ; super || mat_structural end
#     def density ; mat_wood.solid_density end
#
#     alias wood plant
#     def initialize *a
#       super
#       raise ArgumentError, "Unknown wood id: #{id}" unless wood && tree?
#     end
#   end
#
  class Quality < Thing
    def self.index_translation ; (0 ... DFHack::ItemQuality::ENUM.length) end
    def self.find_quality id ; DFHack::ItemQuality::ENUM[id] end

    def token ; self.class.find_quality quality_index end
    def to_s ; "#{super} @quality_index=#{index}" end

    attr_reader :quality_index
    def initialize index, link: nil
      @quality_index = index
      super index, link: link
      # raise RuntimeError, "Unknown quality level: #{id}" unless quality
    end
  end

end

module DFStock
  module AnimalMod
    extend Scaffold
    add_flag(:empty_traps)
    add_flag(:empty_cages)
    add_array(Creature, :animals, :enabled)
  end

  module FoodMod
  #   extend Scaffold
  #   add_flag(:prepared_meals) # this is expected to be ignored because it's a no-op
  #   add_array(Meat, :meat)
  #   add_array(Fish, :fish)
  #   add_array(UnpreparedFish, :unprepared_fish)
  #   add_array(Egg, :egg)
  #   add_array(Plant, :plants)
  # # add_array(DrinkPlant, :drink_plant)
  # # add_array(DrinkAnimal, :drink_animal)
  # # add_array(CheesePlant, :cheese_plant)
  # # add_array(CheeseAnimal, :cheese_animal)
  #   add_array(Seed, :seeds)
  #   add_array(Leaf, :leaves)
  # # add_array(PowderCreature, :powder_creature)
  #   add_array(PowderPlant, :powder_plant)
  # # add_array(Glob, :glob)
  # # add_array(GlobPaste, :glob_paste)
  # # add_array(GlobPressed, :glob_pressed)
  # # add_array(LiquidPlant, :liquid_plant)
  # # add_array(LiquidAnimal, :liquid_animal)
  # # add_array(LiquidMisc, :liquid_misc)
  end

  module FurnitureMod
    extend Scaffold
    # add_array(Furniture, :type)
    add_array(Metal, :metals, :mats)
    # add_array(OtherFurnitureMaterial, :other_materials, :other_mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
    # FurnClass has .sand_bag method but it does not appear to function, and is not mapped to type[-1]
    #           does not have a .stone method
  end

  module StoneMod
    extend Scaffold
    add_array(Ore, :ore, :mats)
    add_array(EconomicStone, :economic, :mats)
    add_array(OtherStone, :other, :mats)
    add_array(Clay, :clay, :mats)
  end

  module AmmoMod
    extend Scaffold
    # add_array(Sheet, :type)
    add_array(Metal, :metals, :mats)
    # add_array(OtherAmmoMaterial, :other_materials, :other_mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
  end

  module CoinMod
    extend Scaffold
    # FIXME Not metals - many more materials
    # add_array(Metal, :metals, :mats)
  end

  module BarsBlocksMod
    extend Scaffold
    add_array(Metal, :bars_metals, :bars_mats)
    add_array(Metal, :blocks_metals, :blocks_mats)
  end

  module GemsMod
    extend Scaffold
    # add_array(RoughGems, :rough_gems, :rough_mats)
    # add_array(CutGems, :cut_gems, :cut_mats)
    # add_array(RoughOtherGems, :rough_other_gems, :rough_other_mats)
    # add_array(CutOtherGems, :cut_other_gems, :cut_other_mats)
  end

  module FinishedGoodsMod
    extend Scaffold
    # mats # stone/clay, metal, gem
    # other_mats
    # type
    add_array(Metal, :metals, :mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
  end

  module LeatherMod
    extend Scaffold
    # add_array(Leather, :leather, :mats)
  end

  module ClothMod
    extend Scaffold
    # add_array(ThreadSilk, :thread_silk)
    # add_array(ThreadPlant, :thread_plant)
    # add_array(ThreadYarn, :thread_yarn)
    # add_array(ThreadMetal, :thread_metal)
    # add_array(ClothSilk, :cloth_silk)
    # add_array(ClothPlant, :cloth_plant)
    # add_array(ClothYarn, :cloth_yarn)
    # add_array(ClothMetal, :cloth_metal)
  end

  module WoodMod
    extend Scaffold
    # add_array(Wood, :wood, :mats)
  end

  module WeaponsMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    # trapcomp_type
    # weapon_type
    # mats # stone + metal
    # other_mats
    add_array(Metal, :metals, :mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
  end

  module ArmorMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    # body
    # feet
    # hands
    # head
    # legs
    # shield
    # mats
    # other_mats
    add_array(Metal, :metals, :mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
  end

  module SheetMod
    extend Scaffold
    # add_array(Paper, :paper)
    # add_array(Parchment, :parchment)
  end

end

if self.class.const_defined? :DFHack
  class DFHack::StockpileSettings_TAnimals       ; include DFStock::AnimalMod end
  class DFHack::StockpileSettings_TFood          ; include DFStock::FoodMod end
  class DFHack::StockpileSettings_TFurniture     ; include DFStock::FurnitureMod end
  # Corpses
  # Refuse
  class DFHack::StockpileSettings_TStone         ; include DFStock::StoneMod end
  class DFHack::StockpileSettings_TAmmo          ; include DFStock::AmmoMod end
  class DFHack::StockpileSettings_TCoins         ; include DFStock::CoinMod end
  class DFHack::StockpileSettings_TBarsBlocks    ; include DFStock::BarsBlocksMod end
  class DFHack::StockpileSettings_TGems          ; include DFStock::GemsMod end
  class DFHack::StockpileSettings_TFinishedGoods ; include DFStock::FinishedGoodsMod end
  class DFHack::StockpileSettings_TLeather       ; include DFStock::LeatherMod end
  class DFHack::StockpileSettings_TCloth         ; include DFStock::ClothMod end
  class DFHack::StockpileSettings_TWood          ; include DFStock::WoodMod end
  class DFHack::StockpileSettings_TWeapons       ; include DFStock::WeaponsMod end
  class DFHack::StockpileSettings_TArmor         ; include DFStock::ArmorMod end
  class DFHack::StockpileSettings_TSheet         ; include DFStock::SheetMod end
  class DFHack::BuildingStockpilest
    def allow_organic      ; settings.allow_organic end
    def allow_organic=   b ; settings.allow_organic= b end
    def allow_inorganic    ; settings.allow_inorganic end
    def allow_inorganic= b ; settings.allow_inorganic= b end
    def stock_flags        ; settings.flags end
    def animals            ; settings.animals end
    # def food               ; settings.food end
    def furniture          ; settings.furniture end
    def corpses            ; settings.corpses end
    def refuse             ; settings.refuse end
    def stone              ; settings.stone end
    def ammo               ; settings.ammo end
    def coins              ; settings.coins end
    def bars_blocks        ; settings.bars_blocks end
    def gems               ; settings.gems end
    def finished_goods     ; settings.finished_goods end
    def leather            ; settings.leather end
    def cloth              ; settings.cloth end
    def wood               ; settings.wood end
    def weapons            ; settings.weapons end
    def armor              ; settings.armor end
    def sheet              ; settings.sheet end
  end

  class DFHack::StockpileSettings
    def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
    def inspect ; "#<#{to_s}>" end
  end
end



#   # All lists and flags together, in one list of [cat:subcat:name,v] pairs. Or, just a list of 'c:s:n', and you query for the values? Is it only the true values?
# # require 'protocol_buffers'
# #   # The goal is to toggle stock by specific item, by material, or by regex, and globally or in a category
# #   # Also, to toggle the flags (category X, allow plant, etc) and set the numeric options (wheelbarrows, etc)
# #   #
# #   # Also desired is a way to split a stockpile, to ensure that every item in the one is represented in two or more
# #   # piles that are intended to take from the first, cleanly separating goods.
# #   #
# #   # ex:
# #   # pile = Stockpile.new
# #   # pile.accept(/hammer/)
# #   # pile.accept(:weapons, type: [:wood!]) # not wood weapons...?
# #   # pile.forbid(/sword/, :food) # forbids swordferns from food, ignores :weapons category.
# #   #
# #   # modifiers - material, quality, ...?
# #   # The theoretical concept of a stockpile, not the physical implementation
# #     # Read material data by introspection of the running instance of DF
# #     # Things like - is_food, is_millable, etc.
# #     def self.read_dwarf_data
# #     # Categories can be enabled without any items selected - eg. a food stockpile that accepts nothing but still prevents spoilage
# #     # FIXME implement enable/disable - @set_fields?
# #     def  enable_category cats ; categories.each {|cat|  enable cat } end
# #     def disable_category cats ; categories.each {|cat| disable cat } end
# #     # By path, eg: 'food,plants,wheat'
# #     # set('food,prepared_meals', true)
# #     #    add('food,meat,POND_GRABBER_SPLEEN')
# #     # remove('food,meat,POND_GRABBER_SPLEEN')
# #   # bars/iron
# #   # furniture/tables/masterwork/iron
# #   # food/prepared
# #   # seeds/plump-helmet
# #   # Is Stock a specific thing, or a class of things?
# #   # Can two stock-types be combined? table/iron AND table/rock?
# #   # Can types be subtracted? table/rock - table/obsidian - table/masterwork
# #   # Are modifiers a thing which can be added removed?
# #   # table + masterwork
# #   # Are All and None special?
# #   # All - table/iron/masterwork
