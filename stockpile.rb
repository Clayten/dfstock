$LOAD_PATH << File.dirname(__FILE__)
require 'thing/thing'
require 'scaffold'

module DFStock
  def self.clear_error_before_loading
    return if $!.nil?
    puts "Clearing lingering error message"
    begin
      load '~/foo'
    rescue LoadError => e
      puts "Rescuing"
    end
  end
  def self.loadfile fn
    # puts "Loading #{fn}"
    load fn
  end
  def self.libs
    Dir.glob("#{File.dirname __FILE__}/**/*rb")
  end
  def self.reload
    return :already_reloading if caller.any? {|c| c =~ /:in `reload'/ }
    clear_error_before_loading
    libs.each {|f| loadfile f }
  end
end
DFStock.reload

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
    def enabled ; all_items.select {|i| i.linked? && i.enabled? } end

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

    def find_by_token path_or_subcat, token = nil
      if token ;    subcat        = path_or_subcat
      else     ; _, subcat, token = path_or_subcat.split(',').map(:to_sym)
      end
      raise "No such subcategory #{subcat}" unless respond_to? subcat
      send(subcat).find {|x| x.token == token }
    end

    def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
    def inspect ; "#<#{to_s}>" end
  end

end

# The Settings Categories are intended to have accessors for classes of items
class DFHack::StockpileSettings_TAnimals       ; include DFStock::StockFinder, DFStock::AnimalMod
  def enable ; raise "Not functional, doesn't enable entries" end
end
class DFHack::StockpileSettings_TFood          ; include DFStock::StockFinder, DFStock::FoodMod
  def enable ; raise "Not functional, can't enable sub-categories" end
  def cookable      ; all_items.select(&:edible_cooked?) ; end # just the items, across sub-categories, that can become a meal in a kitchen
  def needs_cooking ; cookable.select {|f| !f.edible_raw? } ; end # just the items, across sub-categories, that need a kitchen to become food
end
class DFHack::StockpileSettings_TFurniture     ; include DFStock::StockFinder, DFStock::FurnitureMod
  def enable ; raise "Not functional, doesn't enable entries" end
end
class DFHack::StockpileSettings_TCorpse        ; include DFStock::StockFinder
  def _memaddr ; hash end # Fake, just to identify the same instance
  def arrays ; {} end # No arrays of items
  def enable ; raise "Not functional" end
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
      # Corpse: 'corpses', # Non-functional, so don't iterate over it
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

  def all_items ; categories.map {|_,c| c.all_items }.compact.flatten end
  # def enabled ; all_items.select {|i| i.linked? && i.enabled? } end
  def enabled ; categories.select {|_,c| c.enabled? }.map {|_,c| c.enabled }.compact.flatten end

  def == o
    (  enabled.map(&:pathname) ==
     o.enabled.map(&:pathname)) &&
    (  categories.map {|_,c| c.features.select {|t,*_| t == :flag }.map {|_,n1,n2,_| c.send(n2 || n1) } }.flatten ==
     o.categories.map {|_,c| c.features.select {|t,*_| t == :flag }.map {|_,n1,n2,_| c.send(n2 || n1) } }.flatten)
  end

  def copy other
    other_items = Hash[*other.all_items.select(&:enabled?).map {|o| [o.pathname, true] }.flatten]
    all_items.each {|i| i.set other_items[i.pathname] }
    categories.each {|cn,c| c.features.select {|t,*_| t == :flag }.each {|_,n1,n2,_| n = n2 || n1 ; c.send("#{n}=", other.send(cn).send(n)) } }
    self
  end

  # Our items minus the other pile's items
  def - other
    other_items = Hash[*other.all_items.map {|o| [o.pathname, o] }.flatten]
    all_items.select {|s|
      next unless o = other_items[s.pathname]
      se = s.linked? && s.enabled?
      oe = o.linked? && o.enabled?
      se && !oe
    }
  end

  def + other
    other_items = Hash[*other.all_items.map {|o| [o.pathname, o] }.flatten]
    all_items.select {|s|
      next unless o = other_items[s.pathname]
      se = s.linked? && s.enabled?
      oe = o.linked? && o.enabled?
      se || oe
    }
  end

  def set_enabled list
    raise "Not a proper match - there should be #{all_items.length} bools" unless items.length == all_items.length
    all_items.each_with_index {|item,i| item.set !!list[i] }
  end

  def find_by_pathname path_or_cat, subcat = nil, token = nil
    cat, subcat, token = path_or_cat.split(',') unless subcat
    cat, subcat = [cat, subcat].map(&:downcase)
    raise "No such category #{      cat}" unless    respond_to?    cat
    send(cat).find_by_token subcat, token
  end

  def status
    puts "StockSelection:"
    puts "\tAllow Organics: #{allow_organic}.\n\tAllow Inorganics: #{allow_inorganic}"

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
  def self.included *x ; super end
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

  def find_by_pathname *a ; settings.find_by_pathname *a end
  def categories          ; settings.categories end
  def all_items           ; settings.all_items end
  def enabled             ; settings.enabled end
  def copy o              ; settings.copy o end
  def == o                ; settings == o end
  def - o                 ; settings - o end
  def + o                 ; settings + o end
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

    settings.status

    true
  end

  def get_links
    links = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }
    links[:stockpile][:give] = self.links.give_to_pile.to_a unless self.links.give_to_pile.empty?
    links[:stockpile][:take] = self.links.take_from_pile.to_a unless self.links.take_from_pile.empty?
    links[:workshop ][:give] = self.links.give_to_workshop.to_a unless self.links.give_to_workshop.empty?
    links[:workshop ][:take] = self.links.take_from_workshop.to_a unless self.links.take_from_workshop.empty?
    # lookup all hauling stops to see which ones point here
    give_stops, take_stops = hauling_stops.
      map {|h| h.stockpiles.map {|s| [h,s] } }.
      inject(&:+).
      select {|h, s| s.building_id == id }.
      partition {|h, s| !s.mode.give }.
      map {|a| a.map &:first }
    links[:hauling  ][:give] = give_stops unless give_stops.empty?
    links[:hauling  ][:take] = take_stops unless take_stops.empty?
    links
  end
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

  def get_links
    links = Hash.new {|h,k| h[k] = [] }
    stockpiles.each {|link|
      mode = link.mode.give ? :give : :take
      building = df.world.buildings.all.find {|b| b.id == link.building_id }
      links[mode] << building
    }
    {:stockpile => links}
  end
end

class DFHack::BuildingWorkshopst
  def get_links
    links = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }
    links[:stockpile][:give] = getStockpileLinks.give_to_pile.to_a unless getStockpileLinks.give_to_pile.empty?
    links[:stockpile][:take] = getStockpileLinks.take_from_pile.to_a unless getStockpileLinks.take_from_pile.empty?
    links
  end
end

# FIXME - for rerunning inheritance during testing
def reinherit ks = nil
  ks ||= ObjectSpace.each_object(Class).select {|k| k < DFStock::Thing }.sort_by {|k| k.ancestors.length }
  # p [:ks, ks]
  ks.each {|k|
    kp = k.ancestors[1]
    # p [:kp, kp, :<=, :k, k]
    kp.inherited k
  }
end
# Reinherit should not be called unless followed by a reload
def fullhack ; rehack ; reinherit ; rehack end
def try &b ; r = wrap &b ; puts(r.backtrace[0..12],'...',r.backtrace[-12..-1]) if r.is_a?(Exception) ; r end
def wrap ; r = nil ; begin ; r = yield ; rescue Exception => e ; $e = e ; end ; r || e end

def buildings ; df.world.buildings.all.select {|x| x.class <= DFHack::Building } end
def stockpiles
  # Stockpiles and Workshops
  $bs = bs = buildings.select {|x|
    x.class == DFHack::BuildingStockpilest ||
    (x.class == DFHack::BuildingWorkshopst &&
		  x.respond_to?(:getStockpileLinks) &&
			x.getStockpileLinks)
  }
end
def hauling_stops
  # HaulingStops - there often are multiple at the same location for manually-guided routes.
  $hs = hs = df.ui.hauling.routes.map {|r| r.stops.to_a }.flatten
end
def pile_at_cursor
  c = df.cursor
  (stockpiles + hauling_stops).find {|b|
    if b.respond_to? :pos # Hauling Stops - Warning: Will only find the first stop at a location
      b.pos.z == c.z &&
        b.pos.x == c.x &&
        b.pos.y == c.y
    elsif b.respond_to?(:room) && b.room.extents
      next unless c.z == b.z
      ox = c.x - b.room.x
      oy = c.y - b.room.y
      next if ox < 0 || ox > b.room.width || oy < 0 || oy > b.room.height
      offset = ox + oy * b.room.width
      b.room.extents[offset] == :Stockpile
    else
      b.z == c.z &&
        b.x1 <= c.x && b.x2 >= c.x &&
        b.y1 <= c.y && b.y2 >= c.y
    end
  }
end

module DFDebugMethodsEnumerable
	def to_hash
		return {} unless _indexenum
		Hash[each_with_index.map {|v,i|
			[_indexenum.sym(i), v]
		}]
	end
	def active ; to_hash.select {|k,v| v }.map {|k,v| k }.sort_by(&:to_s) end
	def a ; active.reject {|k| k.to_s =~ /^BIOME/ } end
end
module DFHack::MemHack::Enumerable ; include DFDebugMethodsEnumerable end
class DFHack::MemHack::StaticArray ; include DFDebugMethodsEnumerable end
class DFHack::MemHack::DfFlagarray ; include DFDebugMethodsEnumerable end
module Enumerable ; def to_hash *x, &b ; to_h *x, &b end end
