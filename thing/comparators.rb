module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module Comparators
    def enum_to_hash e
      return {} unless e.respond_to? :_indexenum
      Hash[e.each_with_index.map {|v,i|
        [e._indexenum.sym(i), v]
      }.select {|k,v| v }]
    end
    def active_flags ms
      ms = [*ms]
      Hash[ms.map {|x|
        x.respond_to?(:flags) ? x.flags : {}
      }.inject({}) {|a,b|
        a.merge Hash[enum_to_hash b]
      }.sort_by {|k,v|
        k.to_s
      }]
    end

    def reaction_products ms = materials
      rps = [*ms].map {|m|
        r = m.reaction_product
        r.id.each_with_index.map {|x,i|
          mt, mi = r.material.mat_type[i], r.material.mat_index[i]
          m = self.class.material_info(mt, mi).material
          [x.to_sym, m]
        }
      }.inject(&:+)
      rps.flatten! if rps
      Hash[*rps]
    end

    def reaction_class ms = materials ; [*ms].map {|m| m.reaction_class.to_a.map(&:to_sym) }.flatten.sort.uniq end

    # {"FAT"=>[:Glob, 390], "MUSCLE"=>[:Meat, 2342], "EYE"=>[:Meat, 2343], ...
    def food_mat_indexes ms = materials
      h = Hash.new {|h,k| h[k] = {} }
      h = {}
      [*ms].flatten.each {|m|
        enum_to_hash(m.food_mat_index).
          reject {|k,v| -1 == v }.
          each {|k,v|
            h[m.id] = [k, v]
          }
      }
      h
    end

    # {:Glob=>["FAT", "TALLOW"], :Meat=>["MUSCLE", "EYE", "BRAIN", "LUNG", ...
    def materials_by_category
      h = Hash.new {|h,k| h[k] = [] }
      food_mat_indexes.map {|m,(k,i)| [k, m] }.
        each {|k,m| h[k] << m }
      h
    end

    def value ; material.material_value if has_material? end

    def  tile_color     ; material.tile_color  if has_material? end
    def build_color     ; material.build_color if has_material? end
    def basic_color     ; material.basic_color if has_material? end
    def state_color     ; material.state_color if has_material? end
    def state_color_str ; enum_to_hash(material.state_color_str).reject {|k,v| v.empty? } if has_material? end
    def colors ; [:tc, tile_color, :buc, build_color, :bac, basic_color, :sc, state_color, :scs, state_color_str] end
    def color
      # fore, back, bright = tile_color.to_a
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
    def raw_name        ; has_raw? && raw.respond_to?(:name)        ? raw.name          : nil end
    def raw_name_plural ; has_raw? && raw.respond_to?(:name_plural) ? raw.name_plural   : raw_name end

    def material_flags ms = nil
      return {} unless has_material?
      cache(:mat_flags, material._memaddr) { active_flags(ms || materials) }
    end
    def raw_flags
      return {} unless has_raw?
      cache(:raw_flags, raw._memaddr) { active_flags([raw]) }
    end
    def raw_base_flags
      return {} unless has_raw? && raw.respond_to?(:base_flags)
      active_flags(raw.base_flags)
    end
    def raw_props_flags
      return {} unless has_raw? && raw.respond_to?(:props)
      enum_to_hash(raw.props.flags)
    end
    def raw_strings
      return [] unless has_raw? && raw.respond_to?(:raw_strings)
      raw.raw_strings
    end

    # Buitings
    def is_glass? ; has_material? && material_flags[:IS_GLASS] end

    def material_ids ; materials.map(&:id) end

    # Plants
    def mat_mill       ; materials.find {|m| m.id == 'MILL' } end
    def mat_drink      ; materials.find {|m| m.id == 'DRINK' } end
    def mat_mead       ; materials.find {|m| m.id == 'MEAD'  } end
    def mat_wood       ; materials.find {|m| m.id == 'WOOD' } end
    def mat_seed       ; materials.find {|m| m.id == 'SEED' } end
    def mat_leaf       ; materials.find {|m| m.id == 'LEAF' } end
    def mat_thread     ; materials.find {|m| m.id == 'THREAD' } end
    def mat_structural ; materials.find {|m| m.id == 'STRUCTURAL' } end
    def mat_paper      ; materials.find {|m| m.reaction_class.any? {|r| r.to_s =~ /PAPER/ } } end

    def mat_alcohol    ; mat_drink || mat_mead end

    def mill?       ; !!mat_mill end
    def drink?      ; !!(mat_drink || mat_mead) end
    def wood?       ; !!mat_wood end
    def seed?       ; !!mat_seed end
    def leaf?       ; !!mat_leaf end
    def thread?     ; !!mat_thread end
    def structural? ; !!mat_structural end

    def edible_cooked?     ; material_flags(material)[:EDIBLE_COOKED] end
    def edible_raw?        ; material_flags(material)[:EDIBLE_RAW] end
    def edible?            ; edible_cooked? || edible_raw? end

    def alcohol_producing? ; !!reaction_products[:DRINK_MAT] end
    def brewable?          ; alcohol_producing? && !%w(DRINK SEED MILL).include?(material.id) end
    def millable?          ; mill? end

    def tree? ; raw_flags[:TREE] if has_raw? end

    def subterranean? ; raw_flags.select {|k,v| v }.keys.any? {|f| f =~ /SUBTERRANEAN/ } end
    def above_ground? ; !subterranean? end

    def growths   ; (has_raw? && raw.respond_to?(:growths)) ? raw.growths.to_a : [] end
    def growth    ; growths.find {|g| g.str_growth_item.include? material.id } end
    def growth_ids ; growths.map(&:id) end
    def grows_fruit? ; growth_ids.include? 'FRUIT' end
    def grows_bud?   ; growth_ids.include? 'BUD' end
    def grows_leaf?  ; growth_ids.include? 'LEAVES' end

    def winter? ; raw_flags[:WINTER] end
    def spring? ; raw_flags[:SPRING] end
    def summer? ; raw_flags[:SUMMER] end
    def autumn? ; raw_flags[:AUTUMN] end
    def crop? ; winter? || spring? || summer? || autumn? end

    # Creatures
    def is_wagon?    ; raw_flags[:EQUIPMENT_WAGON] end
    def is_creature? ; raw.respond_to?(:creature_id) && !is_wagon? end

    def is_stockpile_animal?
      is_creature? && raw.creature_id !~ /^(FORGOTTEN_BEAST|TITAN|DEMON|NIGHT_CREATURE)_/
    end

    # Finds male and female of egg-laying species
    def lays_eggs?        ; cache(:eggs,          index) {    castes.any? {|c| c.flags[:LAYS_EGGS] } } end

    def grazer?           ; cache(:grazer,        index) {    castes.any? {|c| c.flags[:GRAZER] } } end
    def produces_honey?   ; cache(:honey,         index) { materials.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } } end
    def provides_leather? ; cache(:leather,       index) { materials.any? {|mat| mat.id == 'LEATHER' } } end

    def castes
      return [] unless has_raw? && raw.respond_to?(:caste)
      raw.caste
    end
    def caste
      idx =
        if @caste_index                ; @caste_index
        elsif respond_to? :caste_index ;  caste_index
        else                           ;  0
        end
      castes[idx]
    end
    def caste_symbol
      return unless caste
      {'QUEEN'   => '♀', 'FEMALE' => '♀', 'SOLDIER' => '♀', 'WORKER' => '♀',
       'KING'    => '♂',   'MALE' => '♂', 'DRONE' => '♂',
       'DEFAULT' => '?'
      }[caste.caste_id]
    end

    # Inorganics
    def economic_uses
      return [] unless has_raw? && raw.respond_to?(:economic_uses)
      raw.economic_uses
    end

    def is_gem?   ; material_flags[:IS_GEM] end
    def is_stone? ; material_flags[:IS_STONE] end
    def is_metal? ; material_flags[:IS_METAL] end

    def is_soil? ; raw_flags[:SOIL] end

    def is_ore?  ; raw_flags[:METAL_ORE] end

    def is_economic_stone?
      !is_ore? &&
      !is_metal? &&
      !is_soil? &&
      !economic_uses.empty?
    end

    def is_clay?
      return false unless has_raw? and raw.respond_to? :id
       raw.id =~ /CLAY/ &&
      !raw_flags[:AQUIFER] &&
      !is_stone?
    end

    def is_other_stone?
       is_stone? &&
      !is_ore? &&
      !is_economic_stone? &&
      !is_clay? &&
      !material_flags[:NO_STONE_STOCKPILE]
    end

    def is_stone_category? ; is_ore? || is_clay? || is_other_stone? || is_economic_stone?  end

    def is_magma_safe?
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
