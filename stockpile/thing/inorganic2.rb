require 'thing2'

module DFStock

  class Inorganic2 < Thing2
    inorganic_subset { true }

    # These override the scaffolded methods from above and establish Inorganic as the base of this hierarchy
    def self.inorganic2_raws ; inorganic_types end
    # def self.inorganic2_instances ; inorganic2_raws.each_with_index.map {|_,i| new i } end
    # def self.instances ; inorganic2_instances end

    def raw ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_raws")[idx] end
    def material ; raw.material end
    def materials ; [material] end # There's only one

    def token ; title_case material.state_name[:Solid] end
  end

  class Metal2 < Inorganic2
    inorganic_subset {|x| x.is_metal? }
  end

  class MetalThread2 < Metal2
    inorganic_subset {|x| x.material.flags[:STOCKPILE_THREAD_METAL] }
  end

  class CutStone2 < Inorganic2
    inorganic_subset(&:is_stone?)
  end

  class Stone2 < Inorganic2
    # The .is_stone? flag does not correspond to stock-category stones.
    inorganic_subset {|x| x.is_ore? || x.is_clay? || x.is_economic_stone? || x.is_other_stone? }
  end

  class Ore2 < Stone2
    inorganic_subset {|x| x.is_ore? }
  end

  class EconomicStone2 < Stone2
    inorganic_subset {|x| x.is_economic_stone? }

    def token ; super.downcase end
  end

  class OtherStone2 < Stone2
    inorganic_subset {|x| x.is_other_stone? }

    def token ; super.downcase end
  end

  class Clay2 < Stone2
    inorganic_subset {|x| x.is_clay? }
  end

end
