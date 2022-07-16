require 'thing2'

module DFStock
  class Plant2 < Thing2
    from_category :Plants
    def token ; title_case raw.name end
    def link_index ; index end
  end

  class PlantProduct2 < Thing2
    from_raws(:plant, &:crop?)
    def token ; title_case raw.name end
    def link_index ; plant2_index end
  end

  class PlantDrink2 < Thing2
    from_category :PlantDrink
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class PlantCheese2 < Thing2
    from_category :PlantCheese
    def token ; "#{material.state_name[:Liquid]}" end
  end

  class PlantPowder2 < Thing2
    from_category :PlantPowder
    def token ; title_case material.state_name[:Powder] end
  end

  class FruitLeaf2 < Thing2
    from_category :Leaf
    def token ; title_case "#{growth.name}" end
  end

  class Seed2 < Thing2
    from_category :Seed
    def token ; title_case raw.seed_plural end
  end

  class Paste2 < Thing2
    from_category :Paste
    def token ; "#{material.state_name[:Paste]}" end
  end

  class PlantFiber2 < Thing2
    from_category :PlantFiber
    def token ; title_case "#{mat_thread.state_name[:Solid]} Thread" end
  end

  class Paper2 < Thing2
    from_raws(:plant) {|x| x.materials.any? {|mat| mat.reaction_class.any? {|rc| rc =~ /paper/i } } }
    def token ; title_case "#{mat_paper.state_name[:Solid]} Sheet" end
  end

  class Pressed2 < Thing2
    from_category :Pressed
    def token ; "#{material.state_name[:Pressed]}" end
  end

  class PlantExtract2 < Thing2
    from_category :PlantLiquid
    def token ; title_case "#{material.state_name[:Liquid]}" end
  end

  class Tree2 < Thing2
    from_raws(:plant, &:tree?)
    def material ; mat_wood || mat_structural || materials.first end

    def value   ; wood.material_value if wood end
    def color   ; wood.build_color if wood end
    def density ; wood.solid_density if wood end

    def token ; raw.name_plural end
  end
end
