require 'thing'

module DFStock
  class Plant < Thing
    from_category :Plants
    def token ; title_case raw.name end
    def link_index ; index end
  end

  class PlantProduct < Thing
    from_raws(:plant, &:crop?)
    def token ; title_case raw.name end
    def link_index ; plant_index end
  end

  class PlantDrink < Thing
    from_category :PlantDrink
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class PlantCheese < Thing
    from_category :PlantCheese
    def token ; "#{material.state_name[:Liquid]}" end
  end

  class PlantPowder < Thing
    from_category :PlantPowder
    def token ; title_case material.state_name[:Powder] end
  end

  class FruitLeaf < Thing
    from_category :Leaf
    def token ; title_case "#{growth.name}" end
  end

  class Seed < Thing
    from_category :Seed
    def token ; title_case raw.seed_plural end
  end

  class Paste < Thing
    from_category :Paste
    def token ; "#{material.state_name[:Paste]}" end
  end

  class PlantFiber < Thing
    from_category :PlantFiber
    def token ; title_case "#{mat_thread.state_name[:Solid]} Thread" end
  end

  class Paper < Thing
    from_raws(:plant) {|x| x.materials.any? {|mat| mat.reaction_class.any? {|rc| rc =~ /paper/i } } }
    def token ; title_case "#{mat_paper.state_name[:Solid]} Sheet" end
  end

  class Pressed < Thing
    from_category :Pressed
    def token ; "#{material.state_name[:Pressed]}" end
  end

  class PlantExtract < Thing
    from_category :PlantLiquid
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class Tree < Thing
    from_raws(:plant, &:tree?)
    def material ; mat_wood || mat_structural || materials.first end

    def link_index ; plant_index end
    def token ; raw_name_plural end
  end
end
