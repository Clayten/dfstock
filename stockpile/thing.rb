module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module Raw
    def materials ; return [] unless respond_to? :raw ; raw.material.to_a end # NOTE: Redefine as appropriate in the base-class when redefining material.
    def material  ; materials.first end
    def raws ; return false unless raw ; raw.raws.sort end
  end

  module Material
    def material_ids ; materials.map &:id end
    def active_flags fs ; Hash[fs.inject({}) {|a,b| a.merge Hash[b.to_hash.select {|k,v| v }] }.sort_by {|k,v| k.to_s }] end
    def material_flags ms = materials ; ms = [*ms] ; cache(:material_flags, *ms.map(&:id)) { active_flags [*ms].map(&:flags) } end
  end

  class Thing
    include Raw
    include Material
    def self.material_info cat, id ; df::MaterialInfo.new cat, id end
    def self.material cat, id ; material_info(cat, id).material end # FIXME How to create the material directly?

    def self.mat_table ; df.world.raws.mat_table end
    def self.organic_mat_categories ; DFHack::OrganicMatCategory::NUME.keys end
    def self.organic_category cat_name ; cat_name.is_a?(Numeric) ? cat_name : DFHack::OrganicMatCategory::NUME[cat_name] end
    def self.organic_types ; cache(:organics) { mat_table.organic_types.each_with_index.map {|ot,i| ot.zip mat_table.organic_indexes[i] } } end
    def self.organic cat_name, index # eg: (:Fish, 34) -> Creature_ID, Caste_ID
      cat_num = organic_category cat_name
      raise "Unknown category '#{cat_name.inspect}'" unless cat_num
      organic_types[cat_num][index]
    end

    # For a class, list all of its instances
    def self.instances
      nm = self.name.split(':').last.downcase
      [
        nm,                   # fish    -> fish
        (nm + 's'),           # tree    -> trees
        (nm + 'es'),          # glass   -> glasses
        (nm.sub(/f$/,'ves')), # leaf    -> leaves
        (nm.sub(/y$/,'ies'))  # quality -> qualities
      ].each {|mn|
        return send(mn) if respond_to?(mn)
      }
      false
    end

    def self.subclasses
      ObjectSpace.each_object.select {|o| o.is_a?(Class) && o < self }.sort_by(&:to_s)
    end

    private
    def food_indexes *ms ; ms.flatten.inject([]) {|a,m| fmis = m.food_mat_index.to_hash.reject {|k,v| -1 == v } ; a << [m.id, fmis] unless fmis.empty? ; a } end

    def title_case string ; string.split(/\s+/).map(&:downcase).map(&:capitalize).join(' ') end

    public
    def food_mat_indexes ; food_indexes *materials end
    def check_index
      raise "No linked array" unless link
      raise "Linked array is empty - did you enable the category?" if link.empty?
      raise "Index #{index} is out of array bounds (0 ... #{link.length})" unless (0 ... link.length) === index
    end
    def set x ; check_index ; link[index] = !!x end
    def get   ; check_index ; link[index] end
    def  enabled? ; !!get end
    def  enable   ; set true end
    def disable   ; set false end
    def  toggle   ; set !enabled? end

    def  tile_color     ; material.tile_color  if material end
    def build_color     ; material.build_color if material end
    def basic_color     ; material.basic_color if material end
    def state_color     ; material.state_color if material end
    def state_color_str ; material.state_color_str.to_hash.reject {|k,v| v.empty? } if material end
    def colors ; [:tc, tile_color, :buc, build_color, :bac, basic_color, :sc, state_color, :scs, state_color_str] end

    # Cache lookups - this is pretty important for performance
    # @@cache = Hash.new {|h,k| h[k] = {} } unless @@cache if class_variables.include? :@@cache
    def self.internal_cache ; @@cache ||= Hash.new {|h,k| h[k] = {} } end
    def self.cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      internal_cache[cache_id] = yield
    end
    def internal_cache ; self.class.internal_cache end
    def cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      internal_cache[cache_id] = yield
    end
    def self.clear_cache   ; internal_cache.clear end
    def self.inspect_cache ; internal_cache end

    def token ; 'NONE' end
    def to_s ; "#{self.class.name} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} token=#{token.inspect} index=#{index}" end
    def inspect ; "#<#{to_s}>" rescue super end

    def link ; @link end
    def linked? ; link && !link.empty? end

    def is_magma_safe?
      # p [:ims?, self, :material, material]
      return nil unless material && material.heat

      magma_temp = 12000
      mft = material.heat.mat_fixed_temp
      return true  if mft && mft != 60001

      cdp = material.heat.colddam_point
      return false if cdp && cdp != 60001 && cdp < magma_temp

      %w(heatdam ignite melting boiling).all? {|n|
        t = material.heat.send("#{n}_point")
        t == 60001 || t > magma_temp
      }
    end

    attr_reader :index
    def initialize index, link: nil
      raise "You can't instantiate the base class" if self.class == Thing
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @index = index # The index into the 'link'ed array for the thing
      @link  = link
    end
  end

  # # Template
  # class X < Thing
  #   def self.X_indexes ; (0 ... ??.length).to_a end
  #   def self.index_translation ; X_indexes end
  #   def Y_index ; self.class.X_indexes[X_index] end
  #   def to_s ; super + " X_index=#{X_index}" end
  #   attr_reader :X_index
  #   def initialize index, link: nil
  #     @X_index = index
  #     super Y_index, link: link
  #   end
  # end

  class Builtin < Thing
    def self.builtin_materials ; df.world.raws.mat_table.builtin.to_a end
    def self.builtin_indexes ; builtin_materials.each_with_index.reject {|x,i| !x }.map {|v,i| i } end
    def self.builtins ; builtin_indexes.each_index.map {|i| Builtin.new i } end
    def self.index_translation ; builtin_indexes end

    def index ; self.class.builtin_indexes[builtin_index] end
    def material ; self.class.builtin_materials[index] end
    def materials ; [material] end

    def is_glass? ; material.flags[:IS_GLASS] end

    def to_s ; super + " builtin_index=#{builtin_index}" end
    def token ; material.state_name[:Solid] end

    attr_reader :builtin_index
    def initialize index, link: nil
      @builtin_index = index
      super
    end
  end

  class Glass < Builtin
    def self.glass_indexes ; cache(:glasses) { builtins.each_with_index.inject([]) {|a,(m,i)| a << i if m.is_glass? ; a } } end
    def self.glasses ; glass_indexes.each_index.map {|i| Glass.new i } end
    def self.index_translation ; glass_indexes end

    def builtin_index ; self.class.glass_indexes[glass_index] end
    def to_s ; super + " glass_index=#{glass_index}" end

    attr_reader :glass_index
    def initialize index, link: nil
      @glass_index = index
      super builtin_index, link: link
    end
  end

  # raw -> material
  class Inorganic < Thing
    def self.inorganic_raws ; df.world.raws.inorganics end
    def self.inorganic_indexes ; (0 ... inorganic_raws.length).to_a end
    def self.inorganics ; inorganic_indexes.each_index.map {|i| Inorganic.new i } end
    def self.index_translation ; inorganic_indexes end

    def raw ; self.class.inorganic_raws[index] end
    def materials ; [raw.material] end

    def token ; material.state_name[:Solid] end

    def is_gem? ; material.flags[:IS_GEM] end
    def is_stone? ; material.flags[:IS_STONE] end
    def is_metal? ; material.flags[:IS_METAL] end

    def is_soil? ; raw.flags[:SOIL] end
    def is_ore? ; raw.flags[:METAL_ORE] end

    def is_economic_stone?
      !is_ore? &&
      !is_metal? &&
      !is_soil? &&
      !raw.economic_uses.empty?
    end

    def is_clay?
       raw.id =~ /CLAY/ &&
      !raw.flags[:AQUIFER] &&
      !is_stone?
    end

    def is_other_stone?
       is_stone? &&
      !is_ore? &&
      !is_economic_stone? &&
      !is_clay? &&
      !material.flags[:NO_STONE_STOCKPILE]
    end

    def initialize index, link: nil
      super
    end
  end

  class Metal < Inorganic
    def self.metal_indexes ; cache(:metals) { inorganics.each_with_index.inject([]) {|a,(m,i)| a << i if m.is_metal? ; a } } end
    def self.metals ; metal_indexes.each_index.map {|i| Metal.new i } end
    def self.index_translation ; metal_indexes end

    def inorganic_index ; self.class.metal_indexes[metal_index] end
    def to_s ; super + " metal_index=#{metal_index}" end

    attr_reader :metal_index
    def initialize index, link: nil
      @metal_index = index
      super inorganic_index, link: link
    end
  end

  class Gem < Inorganic # Fixme - Why stone_index not inorganic_index?
    def self.gem_indexes ; cache(:gems) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_gem? ; a } } end
    def self.gems ; gem_indexes.each_index.map {|i| Gem.new i } end
    def self.index_translation ; gem_indexes end

    def stone_index ; self.class.gem_indexes[gem_index] end
    def to_s ; super + " gem_index=#{gem_index}" end

    attr_reader :gem_index
    def initialize index, link: nil
      @gem_index = index
      super stone_index, link: link
    end
  end

  class CutStone < Inorganic # NOTE: A Different definition of stone than the stone stockpile
    # FIXME - Should be inorganic_index, not stone_index
    def self.cutstone_indexes ; cache(:cutstones) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_stone? ; a } } end
    def self.cutstones ; cutstone_indexes.each_index.map {|i| CutStone.new i } end
    def self.index_translation ; cutstone_indexes end

    def stone_index ; self.class.cutstone_indexes[cutstone_index] end
    def to_s ; super + " cutstone_index=#{cutstone_index}" end

    attr_reader :cutstone_index
    def initialize index, link: nil
      @cutstone_index = index
      super stone_index, link: link
    end
  end

  class Stone < Inorganic # NOTE: Not IS_STONE, but members of the stone stockpile
    def self.stone_indexes ; (ore_indexes + economic_indexes + other_indexes + clay_indexes).sort end
    def self.stones ; stone_indexes.each_index.map {|i| Stone.new i } end
    def self.index_translation ; stone_indexes end

    def self.ore_indexes      ; cache(:ores)      { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_ore? ; a } } end
    def self.economic_indexes ; cache(:economics) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_economic_stone? ; a } } end
    def self.other_indexes    ; cache(:others)    { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_other_stone? ; a } } end
    def self.clay_indexes     ; cache(:clays)     { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_clay? ; a } } end

    def inorganic_index ; self.class.stone_indexes[stone_index] end
    def to_s ; super + " stone_index=#{stone_index}" end

    attr_reader :stone_index
    def initialize index, link: nil
      @stone_index = index
      super inorganic_index, link: link
    end
  end

  class Ore < Stone # FIXME: Make dependant on Stone indexes, not directly on Inorganic
    def self.ores ; ore_indexes.each_index.map {|i| Ore.new i } end
    def self.index_translation ; ore_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.ore_indexes[ore_index] end
    def to_s ; super + " ore_index=#{ore_index}" end

    attr_reader :ore_index
    def initialize index, link: nil
      @ore_index = index
      super stone_index, link: link
    end
  end

  class EconomicStone < Stone
    def self.economicstones ; economic_indexes.each_index.map {|i| new i } end
    def self.index_translation ; economic_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.economic_indexes[economic_index] end
    def to_s ; super + " economic_index=#{economic_index}" end

    attr_reader :economic_index
    def initialize index, link: nil
      @economic_index = index
      super stone_index, link: link
    end
  end

  class OtherStone < Stone
    def self.otherstones ; other_indexes.each_index.map {|i| OtherStone.new i } end
    def self.index_translation ; other_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.other_indexes[other_index] end
    def to_s ; super + " other_index=#{other_index}" end

    attr_reader :other_index
    def initialize index, link: nil
      @other_index = index
      super stone_index, link: link
    end
  end

  class Clay < Stone
    def self.clays ; clay_indexes.each_index.map {|i| Clay.new i } end
    def self.index_translation ; clay_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.clay_indexes[clay_index] end
    def to_s ; super + " clay_index=#{clay_index}" end

    attr_reader :clay_index
    def initialize index, link: nil
      @clay_index = index
      super stone_index, link: link
    end
  end

  # food/fish[0] = Cuttlefish(F) = raws.creatures.all[446 = raws.mat_table.organic_indexes[1 = :Fish][0]]

  # NOTE: Not all creatures are stockpilable, and not everything in the array is a creature
  # TODO: Derive Animals from this, and use this then non-sparse class to parent eggs.
  class Creature < Thing
    def self.creature_raws ; cache(:creatures) { df.world.raws.creatures.all } end
    def self.creature_indexes ; (0 ... creature_raws.length).to_a end
    def self.creatures ; creature_indexes.each_index.map {|i| Creature.new i } end
    def self.index_translation ; creature_indexes end

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
    def self.index_translation ; animal_indexes end

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
    def self.index_translation ; meat_indexes ; end

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
    def self.index_translation ; fish_indexes ; end

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
    def self.index_translation ; unpreparedfish_indexes ; end

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
    def self.index_translation ; egg_indexes end

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
    def self.index_translation ; creaturedrink_indexes end

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
    def self.index_translation ; creaturecheese_indexes end

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
    def self.index_translation ; creaturepowder_indexes end

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
    def self.index_translation ; silk_indexes end

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
    def self.index_translation ; yarn_indexes end

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
    def self.index_translation ; metalthread_indexes end

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
    def self.index_translation ; fat_indexes end

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
    def self.index_translation ; creatureextract_indexes end

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
    def self.index_translation ; leather_indexes end

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
    def self.index_translation ; parchment_indexes end

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

  class Plant < Thing
    def self.plant_category ; organic_category :Plants end
    def self.plant_raws ; df.world.raws.plants.all end
    def self.plant_types ; organic_types[plant_category] end
    def self.plant_material_infos ; plant_types.map {|(c,i)| material_info c, i } end
    def self.plants ; plant_indexes.each_index.map {|i| Plant.new i } end
    def self.plant_indexes ; (0 ... plant_types.length).to_a end
    def self.index_translation ; plant_indexes end

    def self.find_plant_index raw ; plant_raws.index raw end

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
    def self.index_translation ; plantproduct_indexes end

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
    def self.index_translation ; plantdrink_indexes end

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
    def self.index_translation ; plantcheese_indexes end

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
    def self.index_translation ; plantpowder_indexes end

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
    def self.index_translation ; fruitleaf_indexes end

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
    def self.index_translation ; seed_indexes end

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
    def self.index_translation ; paste_indexes end

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
    def self.index_translation ; plantfiber_indexes end

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
    def self.index_translation ; paper_indexes end

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
    def self.index_translation ; pressed_indexes end

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
    def self.index_translation ; plantextract_indexes end

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
    def self.index_translation ; tree_indexes end
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

  # TODO: Find item raws for these
  class Furniture < Thing
    def self.furniture_types ; DFHack::FurnitureType::NUME.keys end
    def self.furniture_indexes ; (0 ... furniture_types.length).to_a end
    def self.furnitures ; furniture_indexes.map {|i| Furniture.new i } end
    def self.index_translation ; furniture_indexes end

    def furniture ; self.class.furniture_types[furniture_index] end
    def token ; title_case furniture.to_s.sub(/_/,' ') end
    def to_s ; super + " furniture_index=#{furniture_index}" end

    attr_reader :furniture_index
    def initialize index, link: nil
      @furniture_index = index
      super
    end
  end

  class MiscLiquid < Thing
    def self.miscliquid_items ; [Builtin.new(11).material, Inorganic.new(33).material] end
    def self.miscliquid_indexes ; (0 ... self.miscliquid_items.length).to_a end
    def self.miscliquids ; miscliquid_indexes.map {|i| MiscLiquid.new i } end
    def self.index_translation ; miscliquid_indexes end

    def material ; self.class.miscliquid_items[miscliquid_index] end
    def natural_state ; {0 => :Liquid, 1 => :Solid}[miscliquid_index] end
    def token ; material.state_name[natural_state] end
    def to_s ; super + " miscliquid_index=#{miscliquid_index}" end

    attr_reader :miscliquid_index
    def initialize index, link: nil
      @miscliquid_index = index
      super
    end
  end

  class AmmoOtherMaterial < Thing # FIXME: Manual list
    def self.ammoothermaterial_items ; ['Wood', 'Bone'] end
    def self.ammoothermaterial_indexes ; (0 ... ammoothermaterial_items.length).to_a end
    def self.ammoothermaterials ; ammoothermaterial_indexes.map {|i| AmmoOtherMaterial.new i } end
    def self.index_translation ; ammoothermaterial_indexes end

    def token ; self.class.ammoothermaterial_items[ammoothermaterial_index] end
    def to_s ; super + " ammoothermaterial_index=#{ammoothermaterial_index}" end

    attr_reader :ammoothermaterial_index
    def initialize index, link: nil
      @ammoothermaterial_index = index
      super
    end
  end

  class BarOtherMaterial < Thing # FIXME: Manual list
    def self.barothermaterial_items
      # Note - not very consistent, the first four are archetypal, the later depends on its animal (in this case a toad)
      [
        Builtin.new(7).material, # Coal
        Builtin.new(8).material, # Potash
        Builtin.new(9).material, # Ash
        Builtin.new(10).material, # Pearlash
        Creature.new(0).materials[21] # Soap
      ]
    end
    def self.barothermaterial_indexes ; (0 ... barothermaterial_items.length).to_a end
    def self.barothermaterials ; barothermaterial_indexes.map {|i| BarOtherMaterial.new i } end
    def self.index_translation           ; barothermaterial_indexes end

    def material ; self.class.barothermaterial_items[barothermaterial_index] end

    def token ; self.class.barothermaterial_items[barothermaterial_index].id end
    def to_s ; super + " barothermaterial_index=#{barothermaterial_index}" end

    attr_reader :barothermaterial_index
    def initialize index, link: nil
      @barothermaterial_index = index
      super
    end
  end

  class BlockOtherMaterial < Thing # FIXME: Manual list
    def self.blockothermaterial_items ; ['Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood'] end
    def self.blockothermaterial_indexes ; (0 ... blockothermaterial_items.length).to_a end
    def self.blockothermaterials ; blockothermaterial_indexes.map {|i| BlockOtherMaterial.new i } end
    def self.index_translation ; blockothermaterial_indexes end

    def token ; self.class.blockothermaterial_items[blockothermaterial_index] end
    def to_s ; super + " blockothermaterial_index=#{blockothermaterial_index}" end

    attr_reader :blockothermaterial_index
    def initialize index, link: nil
      @blockothermaterial_index = index
      super
    end
  end

  class WeaponOtherMaterial < Thing # FIXME: Manual list - NOTE: Also the ArmorOtherMaterials
    def self.weaponothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def self.weaponothermaterial_indexes ; (0 ... weaponothermaterial_items.length).to_a end
    def self.weaponothermaterials ; weaponothermaterial_indexes.map {|i| WeaponOtherMaterial.new i } end
    def self.index_translation           ; weaponothermaterial_indexes end

    def token ; self.class.weaponothermaterial_items[weaponothermaterial_index] end
    def to_s ; super + " weaponothermaterial_index=#{weaponothermaterial_index}" end

    attr_reader :weaponothermaterial_index
    def initialize index, link: nil
      @weaponothermaterial_index = index
      super
    end
  end

  class FurnitureOtherMaterial < Thing # FIXME: Manual list
    def self.furnitureothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                                             'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def self.furnitureothermaterial_indexes ; (0 ... furnitureothermaterial_items.length).to_a end
    def self.furnitureothermaterials ; furnitureothermaterial_indexes.map {|i| FurnitureOtherMaterial.new i } end
    def self.index_translation           ; furnitureothermaterial_indexes end

    def token ; self.class.furnitureothermaterial_items[furnitureothermaterial_index] end
    def to_s ; super + " furnitureothermaterial_index=#{furnitureothermaterial_index}" end

    attr_reader :furnitureothermaterial_index
    def initialize index, link: nil
      @furnitureothermaterial_index = index
      super
    end
  end

  class FinishedGoodsOtherMaterial < Thing # FIXME: Manual list
    def self.finishedgoodsothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                                                 'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn', 'Wax'] end
    def self.finishedgoodsothermaterial_indexes ; (0 ... finishedgoodsothermaterial_items.length).to_a end
    def self.finishedgoodsothermaterials ; finishedgoodsothermaterial_indexes.map {|i| FinishedGoodsOtherMaterial.new i } end
    def self.index_translation           ; finishedgoodsothermaterial_indexes end

    def token ; self.class.finishedgoodsothermaterial_items[finishedgoodsothermaterial_index] end
    def to_s ; super + " finishedgoodsothermaterial_index=#{finishedgoodsothermaterial_index}" end

    attr_reader :finishedgoodsothermaterial_index
    def initialize index, link: nil
      @finishedgoodsothermaterial_index = index
      super
    end
  end

  class FinishedGood < Thing # FIXME: Manual list
    def self.finishedgood_items ; ['chains', 'flasks', 'goblets', 'musical instruments', 'toys', 'armor', 'footwear', 'headwear',
                                   'handwear', 'figurines', 'amulets', 'scepters', 'crowns', 'rings', 'earrings', 'bracelets',
                                   'large gems', 'totems', 'legwear', 'backpacks', 'quivers', 'splints', 'crutches', 'tools', 'codices'] end
    def self.finishedgood_indexes ; [10, 11, 12, 13, 14, 25, 26, 28, 29, 35, 36, 37, 39, 40, 41, 42, 43, 58, 59, 60, 61, 81, 82, 85, 88] end
    # def self.finishedgood_indexes ; (0 ... finishedgood_items.length).to_a end
    def self.finishedgoods ; (0 ... finishedgood_indexes.length).map {|i| FinishedGood.new i } end
    def self.index_translation ; finishedgood_indexes end

    def index ; self.class.finishedgood_indexes[finishedgood_index] end
    def token ; self.class.finishedgood_items[finishedgood_index] end
    def to_s ; super + " finishedgood_index=#{finishedgood_index}" end

    attr_reader :finishedgood_index
    def initialize index, link: nil
      @finishedgood_index = index
      super self.index, link: link
    end
  end

  class Refuse < Thing # FIXME: Manual list
    # 81 items, plus two flags which sit at [1] and [2] in the list.
    def self.refuse_items ; ["Thing  0", "Thing  1", "Thing  2", "Thing  3", "Thing  4", "Thing  5", "Thing  6", "Thing  7", "Thing  8", "Thing  9", "Thing 10", "Thing 11", "Thing 12", "Thing 13", "Thing 14", "Thing 15", "Thing 16", "Thing 17", "Thing 18", "Thing 19", "Thing 20", "Thing 21", "Thing 22", "Thing 23", "Thing 24", "Thing 25", "Thing 26", "Thing 27", "Thing 28", "Thing 29", "Thing 30", "Thing 31", "Thing 32", "Thing 33", "Thing 34", "Thing 35", "Thing 36", "Thing 37", "Thing 38", "Thing 39", "Thing 40", "Thing 41", "Thing 42", "Thing 43", "Thing 44", "Thing 45", "Thing 46", "Thing 47", "Thing 48", "Thing 49", "Thing 50", "Thing 51", "Thing 52", "Thing 53", "Thing 54", "Thing 55", "Thing 56", "Thing 57", "Thing 58", "Thing 59", "Thing 60", "Thing 61", "Thing 62", "Thing 63", "Thing 64", "Thing 65", "Thing 66", "Thing 67", "Thing 68", "Thing 69", "Thing 70", "Thing 71", "Thing 72", "Thing 73", "Thing 74", "Thing 75", "Thing 76", "Thing 77", "Thing 78", "Thing 79", "Thing 80"] end
    def self.refuse_indexes ; [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 82, 83, 85, 86, 87, 88, 89] end
    def self.refuses ; (0 ... refuse_indexes.length).map {|i| Refuse.new i } end
    def self.index_translation           ; refuse_indexes end

    def token ; self.class.refuse_items[refuse_index] end
    def to_s ; super + " refuse_index=#{refuse_index}" end

    attr_reader :refuse_index
    def initialize index, link: nil
      @refuse_index = index
      super
    end
  end

  class Item < Thing
    def self.item_raws ; df.world.raws.itemdefs.all end
    def self.item_indexes ; (0 ... item_raws.length).to_a end
    def self.items ; item_indexes.map {|i| Item.new i } end
    def self.index_translation ; item_indexes end

    def raw ; self.class.item_raws[item_index] end

    def material ; end
    def materials ; [] end

    def adjective ; raw.adjective if raw.respond_to?(:adjective) && !raw.adjective.empty? end
    def name ; raw.name end
    def name_plural ; raw.respond_to?(:name_plural) ? raw.name_plural   : raw.name end
    def flags       ; raw.respond_to?(:flags)       ? raw.flags.a       : [] end
    def base_flags  ; raw.respond_to?(:base_flags)  ? raw.base_flags.a  : [] end
    def props_flags ; raw.respond_to?(:props)       ? raw.props.flags.a : [] end
    def raw_strings ; raw.respond_to?(:raw_strings) ? raw.raw_strings   : [] end

    def to_s ; super + " item_index=#{item_index}" end
    def token ; "#{"#{adjective} " if adjective}#{name_plural}" end

    attr_reader :item_index
    def initialize index, link: nil
      @item_index = index
      super
    end
  end

  class Ammo < Item
    def self.ammo_indexes ; item_raws.each_with_index.select {|i,_| i.class == DFHack::ItemdefAmmost }.map {|_,i| i } end
    def self.ammos ; ammo_indexes.each_index.map {|i| Ammo.new i } end
    def self.index_translation ; ammo_indexes end

    def item_index ; self.class.ammo_indexes[ammo_index] end

    def natural_state ; {0 => :Liquid, 1 => :Solid}[ammo_index] end
    def token ; [raw.adjective, raw.name_plural].reject(&:empty?).map(&:capitalize).join(' ') end
    def to_s ; super + " ammo_index=#{ammo_index}" end

    attr_reader :ammo_index
    def initialize index, link: nil
      @ammo_index = index
      super
    end
  end

  # Bool array is large enough for weapons, not all items.
  class Weapon < Item
    def self.weapon_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefWeaponst }.map {|x,i| i } end
    def self.weapons ; weapon_indexes.each_index.map {|i| Weapon.new i } end
    def self.index_translation ; weapon_indexes end

    def item_index ; self.class.weapon_indexes[weapon_index] end

    def token ; title_case super end
    def to_s ; super + " weapon_index=#{weapon_index}" end

    attr_reader :weapon_index
    def initialize index, link: nil
      @weapon_index = index
      super
    end
  end

  class TrapWeapon < Item
    def self.trapweapon_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefTrapcompst }.map {|x,i| i } end
    def self.trapweapons ; trapweapon_indexes.each_index.map {|i| TrapWeapon.new i } end
    def self.index_translation ; trapweapon_indexes end

    def item_index ; self.class.trapweapon_indexes[trapweapon_index] end

    def token ; title_case super end
    def to_s ; super + " trapweapon_index=#{trapweapon_index}" end

    attr_reader :trapweapon_index
    def initialize index, link: nil
      @trapweapon_index = index
      super
    end
  end

  class ArmorBody < Item
    def self.armorbody_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefArmorst }.map {|x,i| i } end
    def self.armorbodys ; armorbody_indexes.each_index.map {|i| ArmorBody.new i } end
    def self.index_translation ; armorbody_indexes end

    def item_index ; self.class.armorbody_indexes[armorbody_index] end

    def token ; title_case super end
    def to_s ; super + " armorbody_index=#{armorbody_index}" end

    attr_reader :armorbody_index
    def initialize index, link: nil
      @armorbody_index = index
      super
    end
  end

  class ArmorHead < Item
    def self.armorhead_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefHelmst }.map {|x,i| i } end
    def self.armorheads ; armorhead_indexes.each_index.map {|i| ArmorHead.new i } end
    def self.index_translation ; armorhead_indexes end

    def item_index ; self.class.armorhead_indexes[armorhead_index] end

    def token ; title_case super end
    def to_s ; super + " armorhead_index=#{armorhead_index}" end

    attr_reader :armorhead_index
    def initialize index, link: nil
      @armorhead_index = index
      super
    end
  end

  class ArmorFeet < Item
    def self.armorfeet_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefShoesst }.map {|x,i| i } end
    def self.armorfeets ; armorfeet_indexes.each_index.map {|i| ArmorFeet.new i } end
    def self.index_translation ; armorfeet_indexes end

    def item_index ; self.class.armorfeet_indexes[armorfeet_index] end

    def token ; title_case super end
    def to_s ; super + " armorfeet_index=#{armorfeet_index}" end

    attr_reader :armorfeet_index
    def initialize index, link: nil
      @armorfeet_index = index
      super
    end
  end

  class ArmorHand < Item
    def self.armorhand_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefGlovesst }.map {|x,i| i } end
    def self.armorhands ; armorhand_indexes.each_index.map {|i| ArmorHand.new i } end
    def self.index_translation ; armorhand_indexes end

    def item_index ; self.class.armorhand_indexes[armorhand_index] end

    def token ; title_case super end
    def to_s ; super + " armorhand_index=#{armorhand_index}" end

    attr_reader :armorhand_index
    def initialize index, link: nil
      @armorhand_index = index
      super
    end
  end

  class ArmorLeg < Item
    def self.armorleg_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefPantsst }.map {|x,i| i } end
    def self.armorlegs ; armorleg_indexes.each_index.map {|i| ArmorLeg.new i } end
    def self.index_translation ; armorleg_indexes end

    def item_index ; self.class.armorleg_indexes[armorleg_index] end

    def token ; title_case super end
    def to_s ; super + " armorleg_index=#{armorleg_index}" end

    attr_reader :armorleg_index
    def initialize index, link: nil
      @armorleg_index = index
      super
    end
  end

  class ArmorShield < Item
    def self.armorshield_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefShieldst }.map {|x,i| i } end
    def self.armorshields ; armorshield_indexes.each_index.map {|i| ArmorShield.new i } end
    def self.index_translation ; armorshield_indexes end

    def item_index ; self.class.armorshield_indexes[armorshield_index] end

    def token ; title_case super end
    def to_s ; super + " armorshield_index=#{armorshield_index}" end

    attr_reader :armorshield_index
    def initialize index, link: nil
      @armorshield_index = index
      super
    end
  end

  class Quality < Thing
    def self.quality_levels ; DFHack::ItemQuality::NUME.keys end
    def self.quality_indexes ; (0 ... quality_levels.length).to_a end
    def self.index_translation ; quality_indexes end
    def self.qualities ; (0 ... index_translation.length).map {|i| new i } end

    def quality ; self.class.quality_levels[quality_index] end
    def token ; quality.to_s end
    def to_s ; "#{super} @quality_index=#{quality_index}" end

    attr_reader :quality_index
    def initialize index, link: nil
      # raise "#{self.class} number #{index} doesn't exist." unless index > 0 and index <= quality_indexes.length
      @quality_index = index
      super
    end
  end

end
