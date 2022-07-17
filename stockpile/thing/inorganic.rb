require 'thing'

module DFStock

  class Inorganic < Thing
    from_raws(:inorganic) { true }
    def token ; title_case material.state_name[:Solid] end
  end

  class Metal < Thing
    from_raws(:inorganic) {|x| x.is_metal? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class MetalThread < Thing
    from_category :MetalThread
    def token ; title_case material.state_name[:Solid] end
  end

  class Gem < Thing
    from_raws(:inorganic, &:is_gem?)
    def token ; material.gem_name2 end
  end

  class CutStone < Thing
    from_raws(:inorganic, &:is_stone?)
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class Stone < Thing
    # The .is_stone? flag does not correspond to stock-category stones.
    from_raws(:inorganic) {|x| x.is_ore? || x.is_clay? || x.is_economic_stone? || x.is_other_stone? }
    def token ; material.state_name[:Solid] end
  end

  class Ore < Thing
    from_raws(:inorganic) {|x| x.is_ore? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class EconomicStone < Thing
    from_raws(:inorganic) {|x| x.is_economic_stone? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class OtherStone < Thing
    from_raws(:inorganic) {|x| x.is_other_stone? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end

  class Clay < Thing
    from_raws(:inorganic) {|x| x.is_clay? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic_index end
  end
end
