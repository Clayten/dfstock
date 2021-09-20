# Force the loading of 'thing.rb' before this file.
DwarfFortressUtils.loadlib(File.join(File.dirname(__FILE__), 'thing.rb'))

module DFStock

  ###
  #
  # These are the definitions of the stockpile-settings accessors we will create.
  #
  # These use the Scaffold plugin to link Thing classes to menu option.
  #
  ###

  module AnimalMod
    extend Scaffold
    add_flag(:empty_traps)
    add_flag(:empty_cages)
    add_array(Animal, :animals, :enabled)
  end

  module FoodMod
    extend Scaffold
    add_flag(:prepared_meals) # this is expected to be ignored because it's a no-op
    add_array(Meat,             :meat)
    add_array(Fish,             :fish)
    add_array(UnpreparedFish,   :unprepared_fish)
    add_array(Egg,              :egg)
    add_array(PlantProduct,     :plants)
    add_array(PlantDrink,       :plant_drink,     :drink_plant)
    add_array(CreatureDrink,    :animal_drink,    :drink_animal)
    add_array(PlantCheese,      :plant_cheese,    :cheese_plant)
    add_array(CreatureCheese,   :creature_cheese, :cheese_animal)
    add_array(Seed,             :seeds)
    add_array(FruitLeaf,        :leaves)
    add_array(PlantPowder,      :plant_powder,    :powder_plant)
    add_array(CreaturePowder,   :animal_powder,   :powder_creature)
    add_array(Fat,              :fat,             :glob)
    add_array(Paste,            :paste,           :glob_paste)
    add_array(Pressed,          :pressed,         :glob_pressed)
    add_array(PlantExtract,     :plant_extract,   :liquid_plant)
    add_array(CreatureExtract,  :animal_extract,  :liquid_animal)
    add_array(MiscLiquid,       :misc_liquid,     :liquid_misc)
  end

  module FurnitureMod
    extend Scaffold
    add_array(Furniture,              :type)
    add_array(CutStone,               :stones, :mats)
    add_array(Metal,                  :metals, :mats)
    add_array(FurnitureOtherMaterial, :other_mats)
    add_array(Quality,                :quality_core)
    add_array(Quality,                :quality_total)
  end

  module RefuseMod
    extend Scaffold
    add_flag( :fresh_raw_hide)
    add_flag(:rotten_raw_hide)
  # add_array(Refuse, :type)
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
    add_array(Ore, :ore, :mats)
    add_array(EconomicStone, :economic, :mats)
    add_array(OtherStone, :other, :mats)
    add_array(Clay, :clay, :mats)
  end

  module AmmoMod
    extend Scaffold
    add_array(Ammo, :type)
    add_array(Metal, :metals, :mats)
    add_array(AmmoOtherMaterial, :other_mats)
    add_array(Quality, :quality_core)
    add_array(Quality, :quality_total)
  end

  module CoinMod
    extend Scaffold
    # add_array(Metal, :metals, :mats) # NOTE: Seems bugged, should just be metals, right...?
  end

  module BarsBlocksMod
    extend Scaffold
    add_array(Metal,              :bars_metals,   :bars_mats)
    add_array(BarOtherMaterial,   :bars_other,    :bars_other_mats)
    add_array(CutStone,           :blocks_stone,  :blocks_mats)
    add_array(Metal,              :blocks_metals, :blocks_mats)
    add_array(BlockOtherMaterial, :blocks_other,  :blocks_other_mats)
  end

  module GemsMod
    extend Scaffold
    add_array(Gem,      :rough_gems,  :rough_mats)
    add_array(Glass,    :rough_glass, :rough_other_mats)
    add_array(Gem,      :cut_gems,    :cut_mats)
    add_array(CutStone, :cut_stone,   :cut_mats)
    add_array(Glass,    :cut_glass,   :cut_other_mats)
  end

  module FinishedGoodsMod
    extend Scaffold
    add_array(FinishedGood,               :type)
    add_array(CutStone,                   :stones, :mats)
    add_array(Metal,                      :metals, :mats)
    add_array(Gem,                        :gems,   :mats)
    add_array(FinishedGoodsOtherMaterial, :other_mats)
    add_array(Quality,                    :quality_core)
    add_array(Quality,                    :quality_total)
  end

  module LeatherMod
    extend Scaffold
    add_array(Leather, :leather, :mats)
  end

  module ClothMod
    extend Scaffold
    add_array(Silk,         :silk_thread, :thread_silk)
    add_array(PlantFiber,  :plant_thread, :thread_plant)
    add_array(Yarn,         :yarn_thread, :thread_yarn)
    add_array(MetalThread, :metal_thread, :thread_metal)
    add_array(Silk,          :silk_cloth, :cloth_silk)
    add_array(PlantFiber,   :plant_cloth, :cloth_plant)
    add_array(Yarn,          :yarn_cloth, :cloth_yarn)
    add_array(MetalThread,  :metal_cloth, :cloth_metal)
  end

  module WoodMod
    extend Scaffold
    add_array(Tree, :tree, :mats)
  end

  module WeaponsMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(Weapon,              :weapons, :weapon_type)
    add_array(TrapWeapon,          :traps,   :trapcomp_type)
    add_array(Metal,               :metals,  :mats)
    add_array(CutStone,            :stones,  :mats)
    add_array(WeaponOtherMaterial, :other_mats)
    add_array(Quality,             :quality_core)
    add_array(Quality,             :quality_total)
  end

  module ArmorMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(ArmorBody,           :body)
    add_array(ArmorHead,           :head)
    add_array(ArmorFeet,           :feet)
    add_array(ArmorHand,           :hands)
    add_array(ArmorLeg,            :legs)
    add_array(ArmorShield,         :shield)
    add_array(Metal,               :metals, :mats)
    add_array(WeaponOtherMaterial, :other_mats)
    add_array(Quality,             :quality_core)
    add_array(Quality,             :quality_total)
  end

  module SheetMod
    extend Scaffold
    add_array(Paper, :paper)
    add_array(Parchment, :parchment)
  end

  # Finds and accesses the flags field in the parent stockpile to allow enabling/disabling the category
  #
  # Stockpile category items aren't directly linked to their container, to go back up the tree such
  # as by asking a child to manipulate its parent is done via ObjectSpace lookup to find the right parent.
  #
  # s = stockpile_at_cursor()
  # s.id
  # -> 12
  # s.food.parent_stockpile.id
  # -> 12
  module StockFinder

    def stock_category_name   ; DFHack::BuildingStockpilest.stock_category_name   self end
    def stock_category_method ; DFHack::BuildingStockpilest.stock_category_method self end

    # Look at all possible parents to find the one pointing to your memory
    def parent_stockpile
      ObjectSpace.each_object(DFHack::BuildingStockpilest).find {|sp|
        sp.z rescue next # guard against something ...?
        sp.send(stock_category_method)._memaddr == _memaddr
      }
    end

    def all_items ; arrays.values.flatten end

    def allow_all
      all_items.each &:enable
      flags.each {|flag, _| send "#{flag}=", true }
      true
    end
    def block_all
      all_items.each &:disable
      flags.each {|flag, _| send "#{flag}=", false }
      true
    end

    def     set x ; parent_stockpile.stock_flags.send "#{stock_category_method}=", !!x ; enabled? end
    def     get   ; parent_stockpile.stock_flags.send "#{stock_category_method}" end
    def  enable   ; set true  end
    def disable   ; set false end
    def enabled?  ; !!get end
  end

end

if self.class.const_defined? :DFHack
  class DFHack::StockpileSettings_TAnimals       ; include DFStock::StockFinder, DFStock::AnimalMod end
  class DFHack::StockpileSettings_TFood          ; include DFStock::StockFinder, DFStock::FoodMod
    def cookable ; raise ; end # just the items, across sub-categories, that need a kitchen to become food
  end
  class DFHack::StockpileSettings_TFurniture     ; include DFStock::StockFinder, DFStock::FurnitureMod end
  # Corpses
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

  class DFHack::BuildingStockpilest
    def allow_organic      ; settings.allow_organic end
    def allow_organic=   b ; settings.allow_organic= b end
    def allow_inorganic    ; settings.allow_inorganic end
    def allow_inorganic= b ; settings.allow_inorganic= b end
    def stock_flags        ; settings.flags end
    def animals            ; settings.animals end
    def food               ; settings.food end
    def furniture          ; settings.furniture end
    def refuse             ; settings.refuse end
    def stone              ; settings.stone end
    def ammo               ; settings.ammo end
    def coins              ; settings.coins end
    def bars_blocks        ; settings.bars_blocks end
    def gems               ; settings.gems end
    def finished_goods     ; settings.finished_goods end
    def leather            ; settings.leather end
    def cloth              ; settings.cloth end
    def wood               ; settings.wood end
    def weapons            ; settings.weapons end
    def armor              ; settings.armor end
    def sheet              ; settings.sheet end

    # From the classname of a category to the name the parent (this) uses to refer to that category
    # Categories in the order they appear in the stockpile
    def self.stock_categories
      {
        Animals: 'animals',
        Food: 'food',
        Furniture: 'furniture',
        Refuse: 'refuse',
        Stone: 'stone',
        Ammo: 'ammo',
        Coins: 'coins',
        BarsBlocks: 'bars_blocks',
        Gems: 'gems',
        FinishedGoods: 'finished_goods',
        Leather: 'leather',
        Cloth: 'cloth',
        Wood: 'wood',
        Weapons: 'weapons',
        Armor: 'armor',
        Sheet: 'sheet'
      }
    end
    def self.stock_category_name obj ; obj.class.to_s.split(/_T/).last.to_sym end
    def self.stock_category_method obj ; stock_categories[stock_category_name obj] end

    def categories ; Hash[self.class.stock_categories.map {|_,m| [m, send(m)] }] end

    def all_items ; categories.map {|_,c| c.all_items }.flatten end

    def status
# "# of Incoming Stockpile Links: #{x.links.take_from_pile.length} - # of Outgoing Stockpile Links: #{x.links.give_to_pile.length}",
# "# of Incoming Workshop Links: #{x.links.take_from_workshop.length} - # of Outgoing Workshop Links: #{x.links.give_to_workshop.length}",
      puts "Stockpile ##{stockpile_number} - #{name.inspect}"
      puts "# Max Barrels: #{max_barrels} - # Max Bins: #{max_bins} - # Max Wheelbarrows: #{max_wheelbarrows}"
      bins, barrels = [:BIN, :BARREL].map {|t| container_type.select {|i| i == t }.length }
      puts "# of Containers: #{container_type.length}, bins: #{bins}, barrels: #{barrels}"
      puts "Allow Organics: #{allow_organic}. Allow Inorganics: #{allow_inorganic}"
      puts "Mode: #{use_links_only == 1 ? 'Use Links Only' : 'Take From Anywhere'}"

      puts "Linked Stops: #{linked_stops.length} #{linked_stops.map(&:name).join}"
      puts "Incoming Stockpile Links: #{links.take_from_pile.length} #{
        links.take_from_pile.map(&:name).join(', ')}"
      puts "Outgoing Stockpile Links: #{links.give_to_pile.length} #{
        links.give_to_pile.map(&:name).join(', ')}"
      puts "Incoming Workshop Links: #{links.take_from_workshop.length} #{
        links.take_from_workshop.map {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"
      puts "Outgoing Workshop Links: #{links.give_to_workshop.length} #{
        links.give_to_workshop.map   {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"

      categories.each {|k, c|
        puts "#{'%20s' % k} #{c.enabled?}"
      }
      true
    end

    # Intended to quickly configure basic piles with some simple code like geekcode
    def set str ; puts "Setting stockpile acceptance to '#{str}'" ; raise end
    def to_s    ; puts "not implemented yet" ; raise end # the inverse of set
  end

  class DFHack::StockpileSettings
    def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
    def inspect ; "#<#{to_s}>" end
  end
end
