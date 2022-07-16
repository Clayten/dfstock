require 'thing'
require 'thing2'
require 'inorganic'
require 'inorganic2'
require 'creature'
require 'creature2'
require 'plant'
require 'plant2'
require 'misc'
require 'misc2'
require 'builtin'
require 'builtin2'
require 'item'
require 'item2'

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
    add_array(Animal2, :enabled, :animals)
  end

  module FoodMod
    extend Scaffold
    add_flag(:prepared_meals)
    add_array(Meat2,             :meat)
    add_array(Fish2,             :fish)
    add_array(UnpreparedFish2,   :unprepared_fish)
    add_array(Egg2,              :egg)
    add_array(PlantProduct2,     :plants)
    add_array(PlantDrink2,       :drink_plant)
    add_array(CreatureDrink2,    :drink_animal)
    add_array(PlantCheese2,      :cheese_plant)
    add_array(CreatureCheese2,   :cheese_animal)
    add_array(Seed2,             :seeds)
    add_array(FruitLeaf2,        :leaves, :fruitleaves)
    add_array(PlantPowder2,      :powder_plant)
    add_array(CreaturePowder2,   :powder_creature)
    add_array(Fat2,              :glob, :glob_fat)
    add_array(Paste2,            :glob_paste)
    add_array(Pressed2,          :glob_pressed)
    add_array(PlantExtract2,     :liquid_plant)
    add_array(CreatureExtract2,  :liquid_animal)
    add_array(MiscLiquid2,       :liquid_misc)
  end

  module FurnitureMod
    extend Scaffold
    add_array(Furniture2,              :type)
    add_array(CutStone2,               :mats,          :stones)
    add_array(Metal2,                  :mats,          :metals)
    add_array(FurnitureOtherMaterial2, :other_mats,    :other_materials)
    add_array(Quality2,                :quality_core)
    add_array(Quality2,                :quality_total)
  end

  module RefuseMod
    extend Scaffold
    add_flag( :fresh_raw_hide)
    add_flag(:rotten_raw_hide)
  # add_array(Refuse2, :type)
    add_array(Animal2, :corpses)
    add_array(Animal2, :body_parts)
    add_array(Animal2, :skulls)
    add_array(Animal2, :bones)
    add_array(Animal2, :shells)
    add_array(Animal2, :teeth)
    add_array(Animal2, :horns)
    add_array(Animal2, :hair)
  end

  module StoneMod
    extend Scaffold
    add_array(Ore2,           :mats, :ore)
    add_array(EconomicStone2, :mats, :economic)
    add_array(OtherStone2,    :mats, :other)
    add_array(Clay2,          :mats, :clay)
  end

  module AmmoMod
    extend Scaffold
    add_array(Ammo2,             :type)
    add_array(Metal2,            :mats,       :metals)
    add_array(AmmoOtherMaterial, :other_mats, :other_materials)
    add_array(Quality2,          :quality_core)
    add_array(Quality2,          :quality_total)
  end

  module CoinMod
    extend Scaffold
    # add_array(Metal, :mats, :metals) # NOTE: Seems bugged, should just be metals, right...?
  end

  module BarsBlocksMod
    extend Scaffold
    add_array(Metal2,              :bars_mats,         :bars_metals)
    add_array(BarOtherMaterial2,   :bars_other_mats,   :bars_other)
    add_array(CutStone2,           :blocks_mats,       :blocks_stone)
    add_array(Metal2,              :blocks_mats,       :blocks_metals)
    add_array(BlockOtherMaterial2, :blocks_other_mats, :blocks_other)
  end

  module GemsMod
    extend Scaffold
    add_array(Gem2,      :rough_mats,       :rough_gems)
    add_array(Glass2,    :rough_other_mats, :rough_glass)
    add_array(Gem2,      :cut_mats,         :cut_gems)
    add_array(Glass2,    :cut_other_mats,   :cut_glass)
    add_array(CutStone2, :cut_mats,         :cut_stone)
  end

  module FinishedGoodsMod
    extend Scaffold
    add_array(FinishedGood2,               :type)
    add_array(CutStone2,                   :mats,       :stones)
    add_array(Metal2,                      :mats,       :metals)
    add_array(Gem2,                        :mats,       :gems)
    add_array(FinishedGoodsOtherMaterial2, :other_mats, :other_materials)
    add_array(Quality2,                    :quality_core)
    add_array(Quality2,                    :quality_total)
  end

  module LeatherMod
    extend Scaffold
    add_array(Leather2, :mats, :leather)
  end

  module ClothMod
    extend Scaffold
    add_array(Silk2,         :thread_silk)
    add_array(PlantFiber2,   :thread_plant)
    add_array(Yarn2,         :thread_yarn)
    add_array(MetalThread2,  :thread_metal)
    add_array(Silk2,         :cloth_silk)
    add_array(PlantFiber2,   :cloth_plant)
    add_array(Yarn2,         :cloth_yarn)
    add_array(MetalThread2,  :cloth_metal)
  end

  module WoodMod
    extend Scaffold
    add_array(Tree2, :mats, :tree)
  end

  module WeaponsMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(Weapon2,              :weapon_type,   :weapons)
    add_array(TrapWeapon2,          :trapcomp_type, :traps)
    add_array(Metal2,               :mats,          :metals)
    add_array(CutStone2,            :mats,          :stones)
    add_array(WeaponOtherMaterial2, :other_mats,    :other_materials)
    add_array(Quality2,             :quality_core)
    add_array(Quality2,             :quality_total)
  end

  module ArmorMod
    extend Scaffold
    add_flag(:usable)
    add_flag(:unusable)
    add_array(ArmorBody2,          :body)
    add_array(ArmorHead2,          :head)
    add_array(ArmorFeet2,          :feet)
    add_array(ArmorHand2,          :hands)
    add_array(ArmorLeg2,           :legs)
    add_array(ArmorShield2,        :shield)
    add_array(Metal2,              :mats,       :metals)
    add_array(ArmorOtherMaterial2, :other_mats, :other_materials)
    add_array(Quality2,             :quality_core)
    add_array(Quality2,             :quality_total)
  end

  module SheetMod
    extend Scaffold
    add_array(Paper2,     :paper)
    add_array(Parchment2, :parchment)
  end

  # Finds and accesses the flags field in the parent stockpile to allow enabling/disabling the category
  #
  # Stockpile category items aren't directly linked to their container, to go back up the tree such
  # as by asking a child to manipulate its parent is done via ObjectSpace lookup to find the right parent.
  #
  # s = stockpile_at_cursor()
  # s.id
  # -> 12
  # s.food.parent.id
  # -> 12
  module StockFinder

    def stock_category_name   ; DFHack::StockpileSettings.stock_category_name   self end
    def stock_category_method ; DFHack::StockpileSettings.stock_category_method self end

    # Look at all possible parents to find the one pointing to your memory
    def parent
      ObjectSpace.each_object(DFHack::StockpileSettings).find {|ss|
        ss.allow_organic rescue next # guard against uninitialized objects
        ss.send(stock_category_method)._memaddr == _memaddr
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

    def     set x ; pr = parent ; raise "Unable to link to parent" unless pr ; pr.flags.send "#{stock_category_method}=", !!x ; enabled? end
    def     get   ; pr = parent ; raise "Unable to link to parent" unless pr ; pr.flags.send "#{stock_category_method}" end
    def  enable   ; set true  end
    def disable   ; set false end
    def enabled?  ; !!get end

    def all_other_categories ; parent.categories.reject {|k,v| k == stock_category_method }.map {|k,v| v } end
  end

end

if self.class.const_defined? :DFHack

  # The Settings Categories are intended to have accessors for classes of items
  class DFHack::StockpileSettings_TAnimals       ; include DFStock::StockFinder, DFStock::AnimalMod
    def enable ; raise "Not functional, doesn't enable entries" end
  end
  class DFHack::StockpileSettings_TFood          ; include DFStock::StockFinder, DFStock::FoodMod
    def enable ; raise "Not functional, can't enable sub-categories" end
    def cookable      ; raise ; end # just the items, across sub-categories, that can become a meal in a kitchen
    def needs_cooking ; raise ; end # just the items, across sub-categories, that need a kitchen to become food
  end
  class DFHack::StockpileSettings_TFurniture     ; include DFStock::StockFinder, DFStock::FurnitureMod
    def enable ; raise "Not functional, doesn't enable entries" end
  end
  class DFHack::StockpileSettings_TCorpse        ; include DFStock::StockFinder
    def _memaddr ; hash end # Fake, just to identify the same instance
    def arrays ; {} end # No arrays of items
  end
  class DFHack::StockpileSettings_TRefuse        ; include DFStock::StockFinder, DFStock::RefuseMod
    def enable ; raise "Not functional, crashes" end
  end
  class DFHack::StockpileSettings_TStone         ; include DFStock::StockFinder, DFStock::StoneMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TAmmo          ; include DFStock::StockFinder, DFStock::AmmoMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TCoins         ; include DFStock::StockFinder, DFStock::CoinMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TBarsBlocks    ; include DFStock::StockFinder, DFStock::BarsBlocksMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TGems          ; include DFStock::StockFinder, DFStock::GemsMod
    def enable ; raise "Not functional, crashes" end
  end
  class DFHack::StockpileSettings_TFinishedGoods ; include DFStock::StockFinder, DFStock::FinishedGoodsMod
    def enable ; raise "Not functional, crashes" end
  end
  class DFHack::StockpileSettings_TLeather       ; include DFStock::StockFinder, DFStock::LeatherMod
    def enable ; raise "Not functional, doesn't enable entries" end
  end
  class DFHack::StockpileSettings_TCloth         ; include DFStock::StockFinder, DFStock::ClothMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TWood          ; include DFStock::StockFinder, DFStock::WoodMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TWeapons       ; include DFStock::StockFinder, DFStock::WeaponsMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TArmor         ; include DFStock::StockFinder, DFStock::ArmorMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end
  class DFHack::StockpileSettings_TSheet         ; include DFStock::StockFinder, DFStock::SheetMod
    def enable ; raise "Not functional, can't enable sub-categories" end
  end


  class DFHack::StockpileSettings
    # From the classname of a category to the name the parent (this) uses to refer to that category
    # Categories in the order they appear in the stockpile
    def self.stock_categories
      {
        Animals: 'animals',
        Food: 'food',
        Furniture: 'furniture',
        Corpse: 'corpses',
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

    # Class to stock-class name - DFHack::StockpileSettings_TAnimals -> :Animals
    def self.stock_category_name obj ; obj.class.to_s.split(/_T/).last.to_sym end

    # Object to stock-class method - Pile.settings.animals -> 'animal'
    def self.stock_category_method obj ; stock_categories[stock_category_name obj] end

    # Look at all possible parents to find the one pointing to your memory
    def parent
      stockpiles = ObjectSpace.each_object(DFHack::BuildingStockpilest).to_a
      trackstops = ObjectSpace.each_object(DFHack::HaulingStop).to_a
      (stockpiles + trackstops).find {|sp|
        sp.settings rescue next # guard against uninitialized objects
        sp.settings._memaddr == _memaddr
      }
    end

    def corpses ; @@corpses ||= {} ; @@corpses[_memaddr] ||= DFHack::StockpileSettings_TCorpse.new ; end

    def categories ; Hash[self.class.stock_categories.map {|_,m| [m, send(m)] }] end

    def all_items ; categories.map {|_,c| c.all_items }.flatten end

    def enabled ; all_items.map {|i| i if i.linked? && i.enabled? } end

    # WARNING: Only items, not other settings
    def == o ; enabled == o.enabled end

    # Our items minus the other pile's items
    def - other
      other_items = other.enabled
      enabled.each_with_index.map {|e, i|
        break if i > 20
        o - other_items[i]
        r = e && !o
        p [i,e,o,r]
        e if r
      }
    end

    def set_enabled list
      raise "Not a proper match - there should be #{all_items.length} bools" unless items.length == all_items.length
      all_items.each_with_index {|item,i| item.set !!list[i] }
    end

    def status
      puts "Allow Organics: #{allow_organic}. Allow Inorganics: #{allow_inorganic}"

      categories.each {|k, c|
        puts "#{'%20s' % k} #{c.enabled?}"
      }
      true
    end

    # Intended to quickly configure basic piles with some simple code like geekcode
    def set str ; puts "Setting stockpile acceptance to '#{str}'" ; raise end
    def to_s    ; raise "not implemented yet" ; end # the inverse of set

    def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
    def inspect ; "#<#{to_s}>" end
  end


  class DFHack::BuildingStockpilest
    alias settings_ settings unless instance_methods.include? :settings_
    def settings ; @@settings ||= {} ; @@settings[_memaddr] ||= settings_ end
  end
  class DFHack::HaulingStop
    alias settings_ settings unless instance_methods.include? :settings_
    def settings ; @@settings ||= {} ; @@settings[_memaddr] ||= settings_ end
  end

  module DFHack::StockForwarder
    # Wrappers to allow the stockpile to be used as the settings object itself.
    def allow_organic       ; settings.allow_organic end
    def allow_organic=   b  ; settings.allow_organic= b end
    def allow_inorganic     ; settings.allow_inorganic end
    def allow_inorganic= b  ; settings.allow_inorganic= b end
    def stock_flags         ; settings.flags end # renamed to avoid conflict
    def animals             ; settings.animals end
    def food                ; settings.food end
    def furniture           ; settings.furniture end
    def refuse              ; settings.refuse end
    def stone               ; settings.stone end
    def ammo                ; settings.ammo end
    def coins               ; settings.coins end
    def bars_blocks         ; settings.bars_blocks end
    def gems                ; settings.gems end
    def finished_goods      ; settings.finished_goods end
    def leather             ; settings.leather end
    def cloth               ; settings.cloth end
    def wood                ; settings.wood end
    def weapons             ; settings.weapons end
    def armor               ; settings.armor end
    def sheet               ; settings.sheet end

    def all_items           ; settings.all_items end
  end


  class DFHack::HaulingStop
    include DFHack::StockForwarder

    def status
      puts "Trackstop ##{id} - #{name.inspect}"

      links = get_links[:stockpile]
      give, take = links[:give], links[:take]
      puts "Incoming Stockpile Links: #{take.length} - #{ take.map(&:name).join(', ')}"
      puts "Outgoing Stockpile Links: #{give.length} - #{ give.map(&:name).join(', ')}"

      puts "StockSelection:"
      settings.status

      true
    end
  end


  class DFHack::BuildingStockpilest
    include DFHack::StockForwarder

    def status
      puts "Stockpile ##{stockpile_number} - #{name.inspect}"
      puts "# Max Barrels: #{max_barrels} - # Max Bins: #{max_bins} - # Max Wheelbarrows: #{max_wheelbarrows}"
      bins, barrels = [:BIN, :BARREL].map {|t| container_type.select {|i| i == t }.length }
      puts "# of Containers: #{container_type.length}, bins: #{bins}, barrels: #{barrels}"
      puts "Mode: #{use_links_only == 1 ? 'Use Links Only' : 'Take From Anywhere'}"

      puts "Linked Stops: #{linked_stops.length} #{linked_stops.map(&:name).join}"
      puts "Incoming Stockpile Links: #{links.take_from_pile.length} - #{
        links.take_from_pile.map(&:name).join(', ')}"
      puts "Outgoing Stockpile Links: #{links.give_to_pile.length} - #{
        links.give_to_pile.map(&:name).join(', ')}"
      puts "Incoming Workshop Links: #{links.take_from_workshop.length} - #{
        links.take_from_workshop.map {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"
      puts "Outgoing Workshop Links: #{links.give_to_workshop.length} - #{
        links.give_to_workshop.map   {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"

      puts "StockSelection:"
      settings.status

      true
    end
  end
end
