module DFStock

  ###
  #
  # These are the definitions of the stockpile-settings accessors we will create.
  #
  # These use the Scaffold plugin to link Thing classes to menu options.
  #
  ###

  module AnimalMod
    extend Scaffold
    add_flag(:empty_traps)
    add_flag(:empty_cages)
    add_array(Animal, :enabled, :animals)
  end

  module FoodMod
    extend Scaffold
    add_flag(:prepared_meals)
    add_array(Meat,             :meat)
    add_array(Fish,             :fish)
    add_array(UnpreparedFish,   :unprepared_fish)
    add_array(Egg,              :egg)
    add_array(PlantProduct,     :plants)
    add_array(PlantDrink,       :drink_plant)
    add_array(CreatureDrink,    :drink_animal)
    add_array(PlantCheese,      :cheese_plant)
    add_array(CreatureCheese,   :cheese_animal)
    add_array(Seed,             :seeds)
    add_array(FruitLeaf,        :leaves, :fruitleaves)
    add_array(PlantPowder,      :powder_plant)
    add_array(CreaturePowder,   :powder_creature)
    add_array(Fat,              :glob, :glob_fat)
    add_array(Paste,            :glob_paste)
    add_array(Pressed,          :glob_pressed)
    add_array(PlantExtract,     :liquid_plant)
    add_array(CreatureExtract,  :liquid_animal)
    add_array(MiscLiquid,       :liquid_misc)
  end

  module FurnitureMod
    extend Scaffold
    add_array(Furniture,              :type)
    add_array(CutStone,               :mats,          :stones)
    add_array(Metal,                  :mats,          :metals)
    add_array(FurnitureOtherMaterial, :other_mats,    :other_materials)
    add_array(Quality,                :quality_core)
    add_array(Quality,                :quality_total)
  end

  module RefuseMod
    extend Scaffold
    # add_flag( :fresh_raw_hide)
    # add_flag(:rotten_raw_hide)
    # add_array(Refuse, :type) # FIXME - Not functional
    add_array(Animal, :corpses)
    add_array(Animal, :body_parts)
    add_array(Animal, :skulls)
    add_array(Animal, :bones)
    add_array(Animal, :shells)
    add_array(Animal, :teeth)
    add_array(Animal, :horns)
    add_array(Animal, :hair)
  end

  module StoneMod
    extend Scaffold
    add_array(Ore,           :mats, :ore)
    add_array(EconomicStone, :mats, :economic)
    add_array(OtherStone,    :mats, :other)
    add_array(Clay,          :mats, :clay)
  end

  module AmmoMod
    extend Scaffold
    add_array(Ammo,              :type)
    add_array(Metal,             :mats,       :metals)
    add_array(AmmoOtherMaterial, :other_mats, :other_materials)
    add_array(Quality,           :quality_core)
    add_array(Quality,           :quality_total)
  end

  module CoinMod
    extend Scaffold
    add_array(Inorganic, :mats, :materials)
  end

  module BarsBlocksMod
    extend Scaffold
    add_array(Metal,              :bars_mats,         :bars_metals)
    add_array(BarOtherMaterial,   :bars_other_mats,   :bars_other)
    add_array(CutStone,           :blocks_mats,       :blocks_stone)
    add_array(Metal,              :blocks_mats,       :blocks_metals)
    add_array(BlockOtherMaterial, :blocks_other_mats, :blocks_other)
  end

  module GemsMod
    extend Scaffold
    add_array(Gem,      :rough_mats,       :rough_gems)
    add_array(Glass,    :rough_other_mats, :rough_glass)
    add_array(Gem,      :cut_mats,         :cut_gems)
    add_array(Glass,    :cut_other_mats,   :cut_glass)
    add_array(CutStone, :cut_mats,         :cut_stone)
  end

  module FinishedGoodsMod
    extend Scaffold
    add_array(FinishedGood,               :type)
    add_array(CutStone,                   :mats,       :stones)
    add_array(Metal,                      :mats,       :metals)
    add_array(Gem,                        :mats,       :gems)
    add_array(FinishedGoodsOtherMaterial, :other_mats, :other_materials)
    add_array(Quality,                    :quality_core)
    add_array(Quality,                    :quality_total)
  end

  module LeatherMod
    extend Scaffold
    add_array(Leather, :mats, :leather)
  end

  module ClothMod
    extend Scaffold
    add_array(Silk,         :thread_silk)
    add_array(PlantFiber,   :thread_plant)
    add_array(Yarn,         :thread_yarn)
    add_array(MetalThread,  :thread_metal)
    add_array(Silk,         :cloth_silk)
    add_array(PlantFiber,   :cloth_plant)
    add_array(Yarn,         :cloth_yarn)
    add_array(MetalThread,  :cloth_metal)
  end

  module WoodMod
    extend Scaffold
    add_array(Tree, :mats, :tree)
  end

  module WeaponsMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(Weapon,              :weapon_type,   :weapons)
    add_array(TrapWeapon,          :trapcomp_type, :traps)
    add_array(Metal,               :mats,          :metals)
    add_array(CutStone,            :mats,          :stones)
    add_array(WeaponOtherMaterial, :other_mats,    :other_materials)
    add_array(Quality,             :quality_core)
    add_array(Quality,             :quality_total)
  end

  module ArmorMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(ArmorBody,          :body)
    add_array(ArmorHead,          :head)
    add_array(ArmorFeet,          :feet)
    add_array(ArmorHand,          :hands)
    add_array(ArmorLeg,           :legs)
    add_array(ArmorShield,        :shield)
    add_array(Metal,              :mats,       :metals)
    add_array(ArmorOtherMaterial, :other_mats, :other_materials)
    add_array(Quality,            :quality_core)
    add_array(Quality,            :quality_total)
  end

  module SheetMod
    extend Scaffold
    add_array(Paper,     :paper)
    add_array(Parchment, :parchment)
  end
end

class DFHack::StockpileSettings_TAnimals       ; include DFStock::StockFinder, DFStock::AnimalMod end
class DFHack::StockpileSettings_TFood          ; include DFStock::StockFinder, DFStock::FoodMod end
class DFHack::StockpileSettings_TFurniture     ; include DFStock::StockFinder, DFStock::FurnitureMod end
class DFHack::StockpileSettings_TCorpse        ; include DFStock::StockFinder end
class DFHack::StockpileSettings_TRefuse        ; include DFStock::StockFinder, DFStock::RefuseMod end
class DFHack::StockpileSettings_TStone         ; include DFStock::StockFinder, DFStock::StoneMod end
class DFHack::StockpileSettings_TAmmo          ; include DFStock::StockFinder, DFStock::AmmoMod end
class DFHack::StockpileSettings_TCoins         ; include DFStock::StockFinder, DFStock::CoinMod end
class DFHack::StockpileSettings_TBarsBlocks    ; include DFStock::StockFinder, DFStock::BarsBlocksMod end
class DFHack::StockpileSettings_TGems          ; include DFStock::StockFinder, DFStock::GemsMod end
class DFHack::StockpileSettings_TFinishedGoods ; include DFStock::StockFinder, DFStock::FinishedGoodsMod end
class DFHack::StockpileSettings_TLeather       ; include DFStock::StockFinder, DFStock::LeatherMod end
class DFHack::StockpileSettings_TCloth         ; include DFStock::StockFinder, DFStock::ClothMod end
class DFHack::StockpileSettings_TWood          ; include DFStock::StockFinder, DFStock::WoodMod end
class DFHack::StockpileSettings_TWeapons       ; include DFStock::StockFinder, DFStock::WeaponsMod end
class DFHack::StockpileSettings_TArmor         ; include DFStock::StockFinder, DFStock::ArmorMod end
class DFHack::StockpileSettings_TSheet         ; include DFStock::StockFinder, DFStock::SheetMod end
