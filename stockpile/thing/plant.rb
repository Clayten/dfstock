require 'thing'

module DFStock
  class Plant < Thing
    from_raws(:plant) { true }
    def name ; title_case raw.name end
  end

  class PlantProduct < Thing # The 'plants' stock category, just the crops
    from_raws(:plant, &:crop?)
    # PlantProduct needs to be defined from raws but it should behave as a single-material-item like from_category
    def materials ; [material] end

    def link_index ; plant_index end
    def name ; title_case raw.name end
  end

  class PlantDrink < Thing
    from_category :PlantDrink
    def name ; title_case "#{material.state_name[:Liquid]}" end
  end

  class PlantCheese < Thing
    from_category :PlantCheese
    def name ; "#{material.state_name[:Liquid]}" end
  end

  class PlantPowder < Thing
    from_category :PlantPowder
    def name ; title_case material.state_name[:Powder] end
  end

  class FruitLeaf < Thing
    from_category :Leaf
    def name ; title_case "#{growth.name}" end
  end

  class Seed < Thing
    from_category :Seed
    def name ; title_case raw.seed_plural end
  end

  class Paste < Thing
    from_category :Paste
    def name ; "#{material.state_name[:Paste]}" end
  end

  class PlantFiber < Thing
    from_category :PlantFiber
    def name ; title_case "#{mat_thread.state_name[:Solid]} Thread" end
  end

  class Paper < Thing
    from_raws(:plant) {|x| x.materials.any? {|mat| mat.reaction_class.any? {|rc| rc =~ /paper/i } } }
    def name ; title_case "#{mat_paper.state_name[:Solid]} Sheet" end
  end

  class Pressed < Thing
    from_category :Pressed
    def name ; "#{material.state_name[:Pressed]}" end
  end

  class PlantExtract < Thing
    from_category :PlantLiquid
    def name ; title_case "#{material.state_name[:Liquid]}" end
  end

  class Tree < Thing
    from_raws(:plant, &:tree?)
    def material ; mat_wood || mat_structural || materials.first end

    def link_index ; plant_index end
    def name ; raw_name_plural end
  end
end
