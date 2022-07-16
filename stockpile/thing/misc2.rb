require 'thing/thing'

module DFStock
  class Furniture2 < Thing2
    from_list DFHack::FurnitureType::NUME.keys
    def token ; type.to_s.sub(/_/,' ').downcase end
  end

  class MiscLiquid2 < Thing2
    from_list [materials_builtin[11], raws_inorganic[33].material]
    def material ; type end
    def token ; material.state_name[:Liquid] end
  end

  class AmmoOtherMaterial2 < Thing2
    from_list ['Wood', 'Bone']
  end

  class BarOtherMaterial2 < Thing2
    from_list [ # Note - not very consistent, the first four are archetypal, the later depends on its animal (in this case a toad)
        Builtin.new(7).material, # Coal
        Builtin.new(8).material, # Potash
        Builtin.new(9).material, # Ash
        Builtin.new(10).material, # Pearlash
        Creature.new(0).materials[21] # Soap
      ]
    def material ; type end
    def token ; title_case material.id end
  end

  class BlockOtherMaterial2 < Thing2
    from_list ['Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood']
  end

  class WeaponOtherMaterial2 < Thing2
    from_list ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn']
  end

  class ArmorOtherMaterial2 < Thing2 # same as WeaponOtherMaterial
    from_list ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn']
  end

  class FurnitureOtherMaterial2 < Thing2
    from_list ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
               'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn']
  end

  class FinishedGoodsOtherMaterial2 < Thing2
    from_list ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
               'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn', 'Wax']
  end

  class FinishedGood2 < Thing2
    from_list ['chains', 'flasks', 'goblets', 'musical instruments', 'toys', 'armor', 'footwear', 'headwear',
               'handwear', 'figurines', 'amulets', 'scepters', 'crowns', 'rings', 'earrings', 'bracelets',
               'large gems', 'totems', 'legwear', 'backpacks', 'quivers', 'splints', 'crutches', 'tools', 'codices']
  end

  class Refuse2 < Thing2
    # 81 items, plus two flags which sit at [1] and [2] in the list.
    from_list(81.times.map {|i| "Thing #{i}" })
  end

  class Quality2 < Thing2
    qualities = DFHack::ItemQuality::NUME.keys
    qualities[0] = :Standard
    from_list qualities.map(&:to_s)
  end
end
