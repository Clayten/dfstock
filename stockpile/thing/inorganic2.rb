require 'thing2'

module DFStock

  class Creature2 < Thing2
    def self.creature2_raws ; raws_creature end
    def self.creature2_indexes ; (0...creature2_raws.length).to_a end

    def raw      ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_raws")[idx] end
    def material ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_materials")[idx] end
    def materials ; raw.material end

    def caste_index ; @caste_index ||= 0 end
    def caste ; raw.caste[caste_index] end

    def token ; title_case raw.name[1] end

    def initialize idx, caste: nil, **a
      p [:init_creature, idx, :caste, caste, a]
      @creature2_index = idx
      @caste_index = caste
      super idx, **a
    end
  end

  class Meat2 < Creature2
    from_category :Meat
  end

  class Egg2 < Creature2
    from_category :Eggs

    def self.egg2_raws ; egg2_types.map {|creature, caste| DFStock::Creature2.new(creature, caste: caste).raw } end
    def self.egg2_materials ; egg2_raws.map {|r| r.material.find {|m| m.id =~ /YOLK/ } } end

    def creature2_index_override ; self.class.egg2_types[index].first end
    def caste_index              ; self.class.egg2_types[index].last  end

    def initialize idx, link: nil
      # p [:init_egg, idx, !!link]
      @egg2_index = idx
      super creature2_index_override, caste: caste_index, link: link
    end
  end

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
