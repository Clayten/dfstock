module DFStock

  class Inorganic < Thing
    from_raws(:inorganic) { true }
    def name ; title_case material.state_name[:Solid] end
  end

  class Metal < Thing
    from_raws(:inorganic) {|x| x.is_metal? }
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class MetalThread < Thing
    from_category :MetalThread
    def name ; title_case material.state_name[:Solid] end
  end

  class Gem < Thing
    from_raws(:inorganic, &:is_gem?)
    def name ; material.gem_name2 == 'STP' ? "#{material.gem_name1}s" : material.gem_name2 end
    def link_index ; inorganic_index end
  end

  class CutStone < Thing
    from_raws(:inorganic, &:is_stone?)
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class Stone < Thing
    # The .is_stone? flag does not correspond to stock-category stones.
    from_raws(:inorganic) {|x| x.is_ore? || x.is_clay? || x.is_economic_stone? || x.is_other_stone? }
    def name ; material.state_name[:Solid] end
  end

  class Ore < Thing
    from_raws(:inorganic) {|x| x.is_ore? }
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class EconomicStone < Thing
    from_raws(:inorganic) {|x| x.is_economic_stone? }
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class OtherStone < Thing
    from_raws(:inorganic) {|x| x.is_other_stone? }
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class Clay < Thing
    from_raws(:inorganic) {|x| x.is_clay? }
    def name ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end
end
