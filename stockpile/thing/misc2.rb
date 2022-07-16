require 'thing/thing'

module DFStock
  class Furniture2 < Thing2
    def self.types ; DFHack::FurnitureType::NUME.keys end

    def furniture ; self.class.types[index] end
    def token ; furniture.to_s.sub(/_/,' ').downcase end
  end

  class MiscLiquid2 < Thing2
    def self.materials ; [materials_builtin[11], raws_inorganic[33].material] end

    def raw ; false ; end
    def token ; material.state_name[:Liquid] end
  end

  class AmmoOtherMaterial2 < Thing2
    def self.types ; ['Wood', 'Bone'] end

    def token ; self.class.types[index] end
  end

  class BarOtherMaterial2 < Thing2
    def self.materials
      [ # Note - not very consistent, the first four are archetypal, the later depends on its animal (in this case a toad)
        Builtin.new(7).material, # Coal
        Builtin.new(8).material, # Potash
        Builtin.new(9).material, # Ash
        Builtin.new(10).material, # Pearlash
        Creature.new(0).materials[21] # Soap
      ]
    end
    def token ; title_case material.id end
  end

  class BlockOtherMaterial2 < Thing2
    def self.types ; ['Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood'] end
    def token ; self.class.types[index] end
  end

  class WeaponOtherMaterial2 < Thing2
    def self.types ; ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def token ; self.class.types[index] end
  end

  class ArmorOtherMaterial2 < Thing2 # same as WeaponOtherMaterial
    def self.types ; ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def token ; self.class.types[index] end
  end

  class FurnitureOtherMaterial2 < Thing2
    def self.types ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                      'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def token ; self.class.types[index] end
  end

  class FinishedGoodsOtherMaterial2 < Thing2
    def self.types ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                      'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn', 'Wax'] end
    def token ; self.class.types[index] end
  end

  class FinishedGood2 < Thing2
    def self.types ; ['chains', 'flasks', 'goblets', 'musical instruments', 'toys', 'armor', 'footwear', 'headwear',
                      'handwear', 'figurines', 'amulets', 'scepters', 'crowns', 'rings', 'earrings', 'bracelets',
                      'large gems', 'totems', 'legwear', 'backpacks', 'quivers', 'splints', 'crutches', 'tools', 'codices'] end
    def token ; self.class.types[index] end
  end

  class Refuse2 < Thing2
    # 81 items, plus two flags which sit at [1] and [2] in the list.
    def self.refuse_items ; ["Thing  0", "Thing  1", "Thing  2", "Thing  3", "Thing  4", "Thing  5", "Thing  6", "Thing  7", "Thing  8", "Thing  9", "Thing 10", "Thing 11", "Thing 12", "Thing 13", "Thing 14", "Thing 15", "Thing 16", "Thing 17", "Thing 18", "Thing 19", "Thing 20", "Thing 21", "Thing 22", "Thing 23", "Thing 24", "Thing 25", "Thing 26", "Thing 27", "Thing 28", "Thing 29", "Thing 30", "Thing 31", "Thing 32", "Thing 33", "Thing 34", "Thing 35", "Thing 36", "Thing 37", "Thing 38", "Thing 39", "Thing 40", "Thing 41", "Thing 42", "Thing 43", "Thing 44", "Thing 45", "Thing 46", "Thing 47", "Thing 48", "Thing 49", "Thing 50", "Thing 51", "Thing 52", "Thing 53", "Thing 54", "Thing 55", "Thing 56", "Thing 57", "Thing 58", "Thing 59", "Thing 60", "Thing 61", "Thing 62", "Thing 63", "Thing 64", "Thing 65", "Thing 66", "Thing 67", "Thing 68", "Thing 69", "Thing 70", "Thing 71", "Thing 72", "Thing 73", "Thing 74", "Thing 75", "Thing 76", "Thing 77", "Thing 78", "Thing 79", "Thing 80"] end

    def token ; self.class.types[index] end
  end

  class Quality2 < Thing2
    def self.types ; qs = DFHack::ItemQuality::NUME.keys ; qs[0] = :Standard ; qs end
    def token ; self.class.types[index] end
  end
end
