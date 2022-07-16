require 'thing2'

module DFStock

  class Inorganic2 < Thing2
    from_raws(:inorganic) { true }
    def token ; title_case material.state_name[:Solid] end
  end

  class Metal2 < Thing2
    from_raws(:inorganic) {|x| x.is_metal? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end

  class MetalThread2 < Thing2
    from_category :MetalThread
    def token ; title_case material.state_name[:Solid] end
  end

  class Gem2 < Thing2
    from_raws(:inorganic, &:is_gem?)
    def token ; material.gem_name2 end
  end

  class CutStone2 < Thing2
    from_raws(:inorganic, &:is_stone?)
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end

  class Stone2 < Thing2
    # The .is_stone? flag does not correspond to stock-category stones.
    from_raws(:inorganic) {|x| x.is_ore? || x.is_clay? || x.is_economic_stone? || x.is_other_stone? }
    def token ; material.state_name[:Solid] end
  end

  class Ore2 < Thing2
    from_raws(:inorganic) {|x| x.is_ore? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end

  class EconomicStone2 < Thing2
    from_raws(:inorganic) {|x| x.is_economic_stone? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end

  class OtherStone2 < Thing2
    from_raws(:inorganic) {|x| x.is_other_stone? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end

  class Clay2 < Thing2
    from_raws(:inorganic) {|x| x.is_clay? }
    def token ; material.state_name[:Solid] end
    def link_index ; inorganic2_index end
  end
end
