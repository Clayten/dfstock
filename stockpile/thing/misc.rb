require 'thing/thing'

module DFStock

  # TODO: Find item raws for these
  class Furniture < Thing
    def self.furniture_types ; DFHack::FurnitureType::NUME.keys end
    def self.furniture_indexes ; (0 ... furniture_types.length).to_a end
    def self.furnitures ; furniture_indexes.map {|i| Furniture.new i } end
    # def self.index_translation ; furniture_indexes end

    def furniture ; self.class.furniture_types[furniture_index] end
    def token ; title_case furniture.to_s.sub(/_/,' ') end
    def to_s ; super + " furniture_index=#{furniture_index}" end

    attr_reader :furniture_index
    def initialize index, link: nil
      @furniture_index = index
      super
    end
  end

  class MiscLiquid < Thing
    def self.miscliquid_items ; [Builtin.new(11).material, Inorganic.new(33).material] end
    def self.miscliquid_indexes ; (0 ... self.miscliquid_items.length).to_a end
    def self.miscliquids ; miscliquid_indexes.map {|i| MiscLiquid.new i } end
    # def self.index_translation ; miscliquid_indexes end

    def material ; self.class.miscliquid_items[miscliquid_index] end
    def natural_state ; {0 => :Liquid, 1 => :Solid}[miscliquid_index] end
    def token ; material.state_name[natural_state] end
    def to_s ; super + " miscliquid_index=#{miscliquid_index}" end

    attr_reader :miscliquid_index
    def initialize index, link: nil
      @miscliquid_index = index
      super
    end
  end

  class AmmoOtherMaterial < Thing # FIXME: Manual list
    def self.ammoothermaterial_items ; ['Wood', 'Bone'] end
    def self.ammoothermaterial_indexes ; (0 ... ammoothermaterial_items.length).to_a end
    def self.ammoothermaterials ; ammoothermaterial_indexes.map {|i| AmmoOtherMaterial.new i } end
    # def self.index_translation ; ammoothermaterial_indexes end

    def token ; self.class.ammoothermaterial_items[ammoothermaterial_index] end
    def to_s ; super + " ammoothermaterial_index=#{ammoothermaterial_index}" end

    attr_reader :ammoothermaterial_index
    def initialize index, link: nil
      @ammoothermaterial_index = index
      super
    end
  end

  class BarOtherMaterial < Thing # FIXME: Manual list
    def self.barothermaterial_items
      # Note - not very consistent, the first four are archetypal, the later depends on its animal (in this case a toad)
      [
        Builtin.new(7).material, # Coal
        Builtin.new(8).material, # Potash
        Builtin.new(9).material, # Ash
        Builtin.new(10).material, # Pearlash
        Creature.new(0).materials[21] # Soap
      ]
    end
    def self.barothermaterial_indexes ; (0 ... barothermaterial_items.length).to_a end
    def self.barothermaterials ; barothermaterial_indexes.map {|i| BarOtherMaterial.new i } end
    # def self.index_translation           ; barothermaterial_indexes end

    def material ; self.class.barothermaterial_items[barothermaterial_index] end

    def token ; self.class.barothermaterial_items[barothermaterial_index].id end
    def to_s ; super + " barothermaterial_index=#{barothermaterial_index}" end

    attr_reader :barothermaterial_index
    def initialize index, link: nil
      @barothermaterial_index = index
      super
    end
  end

  class BlockOtherMaterial < Thing # FIXME: Manual list
    def self.blockothermaterial_items ; ['Green Glass', 'Clear Glass', 'Crystal Glass', 'Wood'] end
    def self.blockothermaterial_indexes ; (0 ... blockothermaterial_items.length).to_a end
    def self.blockothermaterials ; blockothermaterial_indexes.map {|i| BlockOtherMaterial.new i } end
    # def self.index_translation ; blockothermaterial_indexes end

    def token ; self.class.blockothermaterial_items[blockothermaterial_index] end
    def to_s ; super + " blockothermaterial_index=#{blockothermaterial_index}" end

    attr_reader :blockothermaterial_index
    def initialize index, link: nil
      @blockothermaterial_index = index
      super
    end
  end

  class WeaponOtherMaterial < Thing # FIXME: Manual list - NOTE: Also the ArmorOtherMaterials
    def self.weaponothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Shell', 'Leather', 'Silk', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def self.weaponothermaterial_indexes ; (0 ... weaponothermaterial_items.length).to_a end
    def self.weaponothermaterials ; weaponothermaterial_indexes.map {|i| WeaponOtherMaterial.new i } end
    # def self.index_translation           ; weaponothermaterial_indexes end

    def token ; self.class.weaponothermaterial_items[weaponothermaterial_index] end
    def to_s ; super + " weaponothermaterial_index=#{weaponothermaterial_index}" end

    attr_reader :weaponothermaterial_index
    def initialize index, link: nil
      @weaponothermaterial_index = index
      super
    end
  end

  class FurnitureOtherMaterial < Thing # FIXME: Manual list
    def self.furnitureothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                                             'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn'] end
    def self.furnitureothermaterial_indexes ; (0 ... furnitureothermaterial_items.length).to_a end
    def self.furnitureothermaterials ; furnitureothermaterial_indexes.map {|i| FurnitureOtherMaterial.new i } end
    # def self.index_translation           ; furnitureothermaterial_indexes end

    def token ; self.class.furnitureothermaterial_items[furnitureothermaterial_index] end
    def to_s ; super + " furnitureothermaterial_index=#{furnitureothermaterial_index}" end

    attr_reader :furnitureothermaterial_index
    def initialize index, link: nil
      @furnitureothermaterial_index = index
      super
    end
  end

  class FinishedGoodsOtherMaterial < Thing # FIXME: Manual list
    def self.finishedgoodsothermaterial_items ; ['Wood', 'Plant Cloth', 'Bone', 'Tooth', 'Horn', 'Pearl', 'Shell', 'Leather', 'Silk',
                                                 'Amber', 'Coral', 'Green Glass', 'Clear Glass', 'Crystal Glass', 'Yarn', 'Wax'] end
    def self.finishedgoodsothermaterial_indexes ; (0 ... finishedgoodsothermaterial_items.length).to_a end
    def self.finishedgoodsothermaterials ; finishedgoodsothermaterial_indexes.map {|i| FinishedGoodsOtherMaterial.new i } end
    # def self.index_translation           ; finishedgoodsothermaterial_indexes end

    def token ; self.class.finishedgoodsothermaterial_items[finishedgoodsothermaterial_index] end
    def to_s ; super + " finishedgoodsothermaterial_index=#{finishedgoodsothermaterial_index}" end

    attr_reader :finishedgoodsothermaterial_index
    def initialize index, link: nil
      @finishedgoodsothermaterial_index = index
      super
    end
  end

  class FinishedGood < Thing # FIXME: Manual list
    def self.finishedgood_items ; ['chains', 'flasks', 'goblets', 'musical instruments', 'toys', 'armor', 'footwear', 'headwear',
                                   'handwear', 'figurines', 'amulets', 'scepters', 'crowns', 'rings', 'earrings', 'bracelets',
                                   'large gems', 'totems', 'legwear', 'backpacks', 'quivers', 'splints', 'crutches', 'tools', 'codices'] end
    def self.finishedgood_indexes ; [10, 11, 12, 13, 14, 25, 26, 28, 29, 35, 36, 37, 39, 40, 41, 42, 43, 58, 59, 60, 61, 81, 82, 85, 88] end
    # def self.finishedgood_indexes ; (0 ... finishedgood_items.length).to_a end
    def self.finishedgoods ; (0 ... finishedgood_indexes.length).map {|i| FinishedGood.new i } end
    # def self.index_translation ; finishedgood_indexes end

    def index ; self.class.finishedgood_indexes[finishedgood_index] end
    def token ; self.class.finishedgood_items[finishedgood_index] end
    def to_s ; super + " finishedgood_index=#{finishedgood_index}" end

    attr_reader :finishedgood_index
    def initialize index, link: nil
      @finishedgood_index = index
      super self.index, link: link
    end
  end

  class Refuse < Thing # FIXME: Manual list
    # 81 items, plus two flags which sit at [1] and [2] in the list.
    def self.refuse_items ; ["Thing  0", "Thing  1", "Thing  2", "Thing  3", "Thing  4", "Thing  5", "Thing  6", "Thing  7", "Thing  8", "Thing  9", "Thing 10", "Thing 11", "Thing 12", "Thing 13", "Thing 14", "Thing 15", "Thing 16", "Thing 17", "Thing 18", "Thing 19", "Thing 20", "Thing 21", "Thing 22", "Thing 23", "Thing 24", "Thing 25", "Thing 26", "Thing 27", "Thing 28", "Thing 29", "Thing 30", "Thing 31", "Thing 32", "Thing 33", "Thing 34", "Thing 35", "Thing 36", "Thing 37", "Thing 38", "Thing 39", "Thing 40", "Thing 41", "Thing 42", "Thing 43", "Thing 44", "Thing 45", "Thing 46", "Thing 47", "Thing 48", "Thing 49", "Thing 50", "Thing 51", "Thing 52", "Thing 53", "Thing 54", "Thing 55", "Thing 56", "Thing 57", "Thing 58", "Thing 59", "Thing 60", "Thing 61", "Thing 62", "Thing 63", "Thing 64", "Thing 65", "Thing 66", "Thing 67", "Thing 68", "Thing 69", "Thing 70", "Thing 71", "Thing 72", "Thing 73", "Thing 74", "Thing 75", "Thing 76", "Thing 77", "Thing 78", "Thing 79", "Thing 80"] end
    def self.refuse_indexes ; [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 76, 77, 78, 79, 80, 81, 82, 83, 85, 86, 87, 88, 89] end
    def self.refuses ; (0 ... refuse_indexes.length).map {|i| Refuse.new i } end
    # def self.index_translation           ; refuse_indexes end

    def token ; self.class.refuse_items[refuse_index] end
    def to_s ; super + " refuse_index=#{refuse_index}" end

    attr_reader :refuse_index
    def initialize index, link: nil
      @refuse_index = index
      super
    end
  end

  class Quality < Thing
    def self.quality_levels ; DFHack::ItemQuality::NUME.keys end
    def self.quality_indexes ; (0 ... quality_levels.length).to_a end
    # def self.index_translation ; quality_indexes end
    def self.qualities ; (0 ... index_translation.length).map {|i| new i } end

    def quality ; self.class.quality_levels[quality_index] end
    def token ; quality.to_s end
    def to_s ; "#{super} @quality_index=#{quality_index}" end

    attr_reader :quality_index
    def initialize index, link: nil
      # raise "#{self.class} number #{index} doesn't exist." unless index > 0 and index <= quality_indexes.length
      @quality_index = index
      super
    end
  end

end
