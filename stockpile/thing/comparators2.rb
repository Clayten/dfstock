module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module Comparators2
    def food_indexes ms = materials
      ms.flatten.inject([]) {|a,m| fmis = m.food_mat_index.to_hash.reject {|k,v| -1 == v } ; a << [m.id, fmis] unless fmis.empty? ; a }
    end

    def materials_by_category
      food_indexes.map {|m,i| [i.keys.first, m] }.inject(Hash.new {|h,k| h[k] = [] }) {|h,(k,m)| h[k] << m ; h }
    end

    def  tile_color     ; material.tile_color  if material end
    def build_color     ; material.build_color if material end
    def basic_color     ; material.basic_color if material end
    def state_color     ; material.state_color if material end
    def state_color_str ; material.state_color_str.to_hash.reject {|k,v| v.empty? } if material end
    def colors ; [:tc, tile_color, :buc, build_color, :bac, basic_color, :sc, state_color, :scs, state_color_str] end
    def color
      fore, back, bright = tile_color.to_a
      fore, bright = basic_color.to_a
      color_definitions[[fore, bright]]
    end

    def color_definitions
      {[0,0] => :black,       [0,1] => :dark_gray,
       [1,0] => :blue,        [1,1] => :light_blue,
       [2,0] => :green,       [2,1] => :light_green,
       [3,0] => :cyan,        [3,1] => :light_cyan,
       [4,0] => :red,         [4,1] => :light_red,
       [5,0] => :magenta,     [5,1] => :light_magenta,
       [6,0] => :brown,       [6,1] => :yellow,
       [7,0] => :light_gray,  [7,1] => :white
      }
    end

    def adjective ; raw.adjective if raw.respond_to?(:adjective) && !raw.adjective.empty? end
    def raw_name        ; raw.respond_to?(:name)        ? raw.name          : nil end
    def raw_name_plural ; raw.respond_to?(:name_plural) ? raw.name_plural   : raw_name end
    def raw_flags       ; raw.respond_to?(:flags)       ? raw.flags.a       : [] end
    def raw_base_flags  ; raw.respond_to?(:base_flags)  ? raw.base_flags.a  : [] end
    def raw_props_flags ; raw.respond_to?(:props)       ? raw.props.flags.a : [] end
    def raw_strings     ; raw.respond_to?(:raw_strings) ? raw.raw_strings   : [] end
  end

  module BuiltinComparators2
    def is_glass? ; material_flags[:IS_GLASS] end
  end

  module PlantComparators2
    def growths   ; has_raw? ? raw.growths : [] end
    def growth    ; growths.find {|g| g.str_growth_item.include? material.id } end

    def mat_mill       ; materials.find {|m| m.id == 'MILL' } end
    def mat_drink      ; materials.find {|m| m.id == 'DRINK' } end
    def mat_wood       ; materials.find {|m| m.id == 'WOOD' } end
    def mat_seed       ; materials.find {|m| m.id == 'SEED' } end
    def mat_leaf       ; materials.find {|m| m.id == 'LEAF' } end
    def mat_thread     ; materials.find {|m| m.id == 'THREAD' } end
    def mat_paper      ; materials.find {|m| m.reaction_class.any? {|r| r.to_s =~ /PAPER/ } } end
    def mat_structural ; materials.find {|m| m.id == 'STRUCTURAL' } end

    def mill?       ; !!mat_mill end
    def drink?      ; !!mat_drink end
    def wood?       ; !!mat_wood end
    def seed?       ; !!mat_seed end
    def leaf?       ; !!mat_leaf end
    def thread?     ; !!mat_thread end
    def structural? ; !!mat_structural end

    # FIXME these are wrong for category-based classes
    def edible_cooked?  ; material_flags(material)[:EDIBLE_COOKED] end
    def edible_raw?     ; material_flags(material)[:EDIBLE_RAW] end
    def edible?         ; edible_cooked? || edible_raw? end
    def alcohol_producing? ; has_material? && material_flags[:ALCOHOL_PLANT] end
    def brewable?       ;  alcohol_producing? && !%w(DRINK SEED MILL).include?(material.id) end
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

  module CreatureComparators2
    def is_wagon?    ; raw_flags[:EQUIPMENT_WAGON] end
    def is_creature? ; raw.respond_to?(:creature_id) && !is_wagon? end

    def is_stockpile_animal?
      is_creature? && raw.creature_id !~ /^(FORGOTTEN_BEAST|TITAN|DEMON|NIGHT_CREATURE)_/
    end

    def edible_cooked?    ; cache(:edible_cooked, index) { material_flags[:EDIBLE_COOKED] } end
    def edible_raw?       ; cache(:edible_raw,    index) { material_flags[:EDIBLE_RAW] } end
    def edible?           ; cache(:edible,        index) { edible_cooked? || edible_raw? } end

    # Finds male and female of egg-laying species
    def lays_eggs?        ; cache(:eggs,          index) { raw.caste.any? {|c| c.flags.to_hash[:LAYS_EGGS] } } end

    def grazer?           ; cache(:grazer,        index) { raw.caste.any? {|c| c.flags.to_hash[:GRAZER] } } end
    def produces_honey?   ; cache(:honey,         index) { materials.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } } end
    def provides_leather? ; cache(:leather,       index) { materials.any? {|mat| mat.id == 'LEATHER' } } end

    def caste_symbol
      {'QUEEN'   => '♀', 'FEMALE' => '♀', 'SOLDIER' => '♀', 'WORKER' => '♀',
       'KING'    => '♂',   'MALE' => '♂', 'DRONE' => '♂',
       'DEFAULT' => '?'
      }[caste.caste_id]
    end
  end


  module InorganicComparators2
    def is_gem?   ; material.flags[:IS_GEM] end
    def is_stone? ; material.flags[:IS_STONE] end
    def is_metal? ; material.flags[:IS_METAL] end

    def is_soil? ; raw.flags[:SOIL] end

    def is_ore?  ; raw.flags[:METAL_ORE] end

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

    def is_stone_category? ; is_ore? || is_clay? || is_other_stone? || is_economic_stone?  end

    def is_magma_safe?
      # p [:ims?, self, :heat, material.heat]
      return nil unless has_material? && material.heat

      magma_temp = 12000
      mft = material.heat.mat_fixed_temp
      unless mft == 60001
        # p [:checking, :material_fixed_temperature, mft]
        return true if mft
      end

      cdp = material.heat.colddam_point
      unless cdp == 60001
        # p [:checking, :colddam_point, cdp, :gt, magma_temp]
        return false if cdp > magma_temp
      end

      return false if %w(heatdam ignite melting boiling).any? {|n|
        m = "#{n}_point".to_sym
        t = material.heat.send m
        next if t == 60001
        # p [:checking, m, t, :lt, magma_temp]
        t < magma_temp
      }

      true
    end
  end
end
