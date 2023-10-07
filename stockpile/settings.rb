module DFStock::StockFinder
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

  def stock_category_name   ; DFHack::StockpileSettings.stock_category_name   self end
  def stock_category_method ; DFHack::StockpileSettings.stock_category_method self end

  # Look at all possible settings object parents to find the one pointing to your memory
  def parent
    @parent ||=
    ObjectSpace.each_object(DFHack::StockpileSettings).find {|ss|
      ss.allow_organic rescue next # guard against uninitialized objects
      ss.send(stock_category_method)._memaddr == _memaddr
    }
  end

  def enable_subcategories
    p [:enable_subcategories, self.class]
    return true if enabled? # Don't muck with anything
    parent.flags.send("#{stock_category_method}=", true)
    return true unless respond_to? :features
    features.each {|t,n1,n2,k|
      next unless :array == t
      n = (n1 || n2).to_s
      bool_name = "array_#{n}"
      next unless instance = k.instances.last
      last_index = k.instances.last.link_index
      # p [:creating_arrays_for, stock_category_name, :klass, k, :names, [n1, n2], :bool_array_name, bool_name, :num_instances, k.num_instances, :last_index, last_index]
      bool_array = send bool_name
      0.upto(last_index).each {|i| bool_array[i] = false }
    }
    enabled?
  end

  def all_items ; arrays.values.flatten end
  def enabled_items ; all_items.select {|i| i.enabled? } end
  def enabled_pathnames ; enabled_items.map(&:pathname) end
  def enabled_flags ; raise end

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

  def     set x  ; pr = parent ; raise "Unable to link to parent" unless pr ; pr.flags.send "#{stock_category_method}=", !!x ; enabled? end
  def     get    ; pr = parent ; raise "Unable to link to parent" unless pr ; pr.flags.send "#{stock_category_method}" end
  def  enabled?  ; !!get end
  def  enable    ; enable_subcategories unless enabled? ; set true end
  def disable    ; set false end

  def link_array_by_subcategory sc
    # p [:labs, sc, self]
    f = features.find {|_,bn,dn,_| (dn || bn) == sc }
    raise "No such subcategory as #{sc}" unless f
    nm = 'array_' + f[1].to_s
    boolean_array = send nm
    raise "Category #{stock_category_name} not enabled!" unless enabled?
    raise "SubCategory #{sc} not enabled!" if boolean_array.empty?
    boolean_array
  end
  def set_item subcategory, index, value ; enable unless enabled? ; link_array_by_subcategory(subcategory)[index] = !!value end
  def get_item subcategory, index        ;                        !!link_array_by_subcategory(subcategory)[index] end

  def all_other_categories ; parent.categories.reject {|k,v| k == stock_category_method }.map {|k,v| v } end

  def find_by_token path_or_subcat, token = nil
    if token ;      subcat        = path_or_subcat
    else     ; cat, subcat, token = path_or_subcat.split(DFStock.pathname_separator)
    end
    if cat
      cat.downcase!
      raise "Category provided and does not match, #{cat} vs #{stock_category_method}" if cat != stock_category_method
    end
    subcat.downcase!
    raise "No such subcategory #{subcat}" unless respond_to? subcat
    $sc = send(subcat) ; $sc.find {|x| x.token == token }
  end

  def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
  def inspect ; "#<#{to_s}>" end
end

# The Settings Categories are intended to have accessors for classes of items
class DFHack::StockpileSettings_TAnimals
end
class DFHack::StockpileSettings_TFood
  def cookable      ; all_items.select(&:edible_cooked?) ; end # just the items, across sub-categories, that can become a meal in a kitchen
  def needs_cooking ; cookable.select {|f| !f.edible_raw? } ; end # just the items, across sub-categories, that need a kitchen to become food
end
class DFHack::StockpileSettings_TFurniture
end
class DFHack::StockpileSettings_TCorpse
  def _memaddr ; hash end # Fake, just to identify the same instance
  def arrays ; {} end # No arrays of items
end
class DFHack::StockpileSettings_TRefuse
  def enable ; raise "#{stock_category_name}#enable Not functional" end
end
class DFHack::StockpileSettings_TStone
end
class DFHack::StockpileSettings_TAmmo
end
class DFHack::StockpileSettings_TCoins
end
class DFHack::StockpileSettings_TBarsBlocks
end
class DFHack::StockpileSettings_TGems
end
class DFHack::StockpileSettings_TFinishedGoods
end
class DFHack::StockpileSettings_TLeather
end
class DFHack::StockpileSettings_TCloth
end
class DFHack::StockpileSettings_TWood
end
class DFHack::StockpileSettings_TWeapons
end
class DFHack::StockpileSettings_TArmor
end
class DFHack::StockpileSettings_TSheet
end

module DFHack::StockComparator
  # These operations are only on items, not on flags
  def - other
    # p [:minus, self.class, other.class]
    DFHack::Settings.new(enabled_pathnames - other.enabled_pathnames)
  end

  def + other
    # p [:plus, self.class, other.class]
    DFHack::Settings.new((enabled_pathnames + other.enabled_pathnames).uniq)
  end

  def & other
    # p [:and, self.class, other.class]
    count = Hash.new 0
    (enabled_pathnames + other.enabled_pathnames).each {|pn| count[pn] += 1 }
    DFHack::Settings.new(count.select {|k,c| c == 2 }.map(&:first))
  end

  def ^ other
    # p [:xor, self.class, other.class]
    count = Hash.new 0
    (enabled_pathnames + other.enabled_pathnames).each {|pn| count[pn] += 1 }
    DFHack::Settings.new(count.select {|k,c| c == 1 }.map(&:first))
  end

  def length ; enabled_pathnames.length end
end
class DFHack::Settings
  include DFHack::StockComparator

  attr_accessor :enabled_pathnames
  def initialize list
    @enabled_pathnames = list
  end
end

class DFHack::StockpileSettings
  include DFHack::StockComparator
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

  # Look at all possible settings-containing "buildings" to find the one pointing to your memory
  def parent
    (stockpiles + hauling_stops).find {|sp|
      sp.settings rescue next # guard against uninitialized objects
      sp.settings._memaddr == _memaddr
    }
  end

  def corpses ; @@corpses ||= {} ; @@corpses[_memaddr] ||= DFHack::StockpileSettings_TCorpse.new ; end

  def categories ; Hash[self.class.stock_categories.map {|_,m| [m, send(m)] }] end

  def all_items ; categories.map {|_,c| c.all_items }.flatten end
  def enabled_items ; categories.map {|_,c| c.enabled_items }.flatten.compact end
  def enabled_pathnames ; enabled_items.map(&:pathname) end

  def == o
    (enabled_pathnames == o.enabled_pathnames) &&
    (  categories.map {|_,c| c.features.select {|t,*_| t == :flag }.map {|_,n1,n2,_| c.send(n2 || n1) } }.flatten ==
     o.categories.map {|_,c| c.features.select {|t,*_| t == :flag }.map {|_,n1,n2,_| c.send(n2 || n1) } }.flatten)
  end

  def copy other
    other_items = Hash[*other.enabled_pathnames.map {|x| [x, true] }.flatten]
    all_items.each {|i| e = other_items[i.pathname] ; i.set e unless i.enabled? == !!e }
    # categories.each {|cn,c| c.features.select {|t,*_| t == :flag }.each {|_,n1,n2,_| n = n2 || n1 ; c.send("#{n}=", other.send(cn).send(n)) } }
    self
  end

  def find_by_pathname path_or_cat, subcat = nil, token = nil
    cat, subcat, token = path_or_cat.split(',') unless subcat
    cat, subcat = [cat, subcat].map(&:downcase)
    raise "No such category #{      cat}" unless    respond_to?    cat
    send(cat).find_by_token subcat, token
  end

  def status
    puts "StockSelection:"
    puts "\tAllow Organics: #{allow_organic}\n\tAllow Inorganics: #{allow_inorganic}"

    categories.each {|k, c|
      puts "#{'%20s' % k} #{c.enabled?} - #{c.enabled_pathnames.length} items enabled" if c.enabled?
    }
    true
  end

  # Intended to quickly configure basic piles with some simple code like geekcode
  def set str ; puts "Setting stockpile acceptance to '#{str}'" ; raise end
  def to_s    ; raise "not implemented yet" ; end # the inverse of set

  def to_s ; "#{self.class.name}:#{'0x%016x' % object_id }" end
  def inspect ; "#<#{to_s}>" end
end
