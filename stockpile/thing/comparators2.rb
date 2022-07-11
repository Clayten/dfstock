module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module Comparators2
    def has_raw?      ; !!(raw      rescue false) end
    def has_material? ; !!(material rescue false) end
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
