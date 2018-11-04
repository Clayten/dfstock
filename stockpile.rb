class DwarfFortressUtils

  # The goal is to toggle stock by specific item, by material, or by regex, and globally or in a category
  # Also, to toggle the flags (category X, allow plant, etc) and set the numeric options (wheelbarrows, etc)
  #
  # Also desired is a way to split a stockpile, to ensure that every item in the one is represented in two or more
  # piles that are intended to take from the first, cleanly separating goods.
  #
  # ex:
  # pile = Stockpile.new
  # pile.accept(/hammer/)
  # pile.accept(:weapons, type: [:wood!]) # not wood weapons...?
  # pile.forbid(/sword/, :food) # forbids swordferns from food, ignores :weapons category.
  #
  # modifiers - material, quality, ...?


  # The theoretical concept of a stockpile, not the physical implementation
  class Stockpile

    # private

    # Use the DFHack ProtocolBuffer protofile to define our base stockpile settings object
    def self.load_proto_description
      return if Dfstockpiles::StockpileSettings rescue nil
      load "#{File.dirname __FILE__}/stockpiles.pb.rb"
    end
    load_proto_description

    def self.stockpile_prototype
      Dfstockpiles::StockpileSettings
    end

    def stockpile_prototype ; self.class.stockpile_prototype end

    # Read material data by introspection of the running instance of DF
    # Things like - is_food, is_millable, etc.
    def self.read_dwarf_data
      # FIXME - implement
    rescue StandardError => e
      raise "Failure to read DF data. #{e.class} #{e.message}"
    end

    public

    def self.items

    end
    def self.categories
      items.keys
    end

    def self.decode_stock buf
      sp = Dfstockpiles::StockpileSettings.new
      sp.parse buf
      sp
    end
    def self.encode_stock stockpile
      stockpile.to_s
    end

    def self.read_stockfile fn
      decode_stock File.read(fn, encoding: 'ASCII')
    end
    def self.write_stockfile sp, fn
      File.write fn, encode_stock(sp)
    end

    def self.new_from_file fn
      new read_stockfile fn
    end

    def self.new_from_buffer buf
      new decode_stockfile buf
    end

    def write fn
      self.class.write_stockfile fn, to_s
    end

    # goal - s.select {|i| i.food? } == s.food
    # s.enable 'PLANT:ELEPHANT-HEAD_AMARANTH:SEED' == s.enable 'Elephant-head amaranth' == s.items.each {|i| i.enable if i.name =~ /^Ele.*anth/ }
    #
    # S::Item
    # .quality? -> (min..max) ??
    # - Problem - items can't necessarily be composed into one stockpile if they have different qualities or materials - perhaps by unwanted broadening of the selection
    # -           other times this is what you want. s << 'food' << 'swords' - and it just works. But does it if it accepts too much?
    # - P       - Needs backlink to parent pile.
    #
    # Proposal: s.items.each {|i| s.enable i if i.name =~ /^Ele.*anth/ } - Lighter-weight perhaps.
    #
    #

    def fields ; pile.fields.values end
    def field n ; fields.find {|f| f.name == n.to_sym } end

    def flags      ; fields.select {|f| ProtocolBuffers::Field::BoolField === f }.map {|f| f.name } end
    def categories ; fields.select {|f| ProtocolBuffers::Field::MessageField === f }.map(&:name) end

    def method_missing mn, *args, &b
      if fields.map(&:name).include? mn
        raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 0)" unless args.empty?
        return pile.send mn
      else
        raise NoMethodError, "undefined method `#{mn}' for #{inspect}"
      end
    end

    # Categories can be enabled without any items selected - eg. a food stockpile that accepts nothing but still prevents spoilage
    # FIXME implement enable/disable - @set_fields?
    def  enable_category cats ; categories.each {|cat|  enable cat } end
    def disable_category cats ; categories.each {|cat| disable cat } end

    # The counterpart to the method below
    # reports stored data from a maximal stockpile
    def all_possible_items ; end

    # Will always include max_wheelbarrows even if zero, and use_links_only even if null, but will only include Wood types (etc) that are actually selected (added to the array)
    def recursive_entries x = nil, prefix: '', list: []
      x ||= pile
      # p [:recursive_entries, :x, x.class, :prefix, prefix, :list_length, list.length]
      x.fields.values.each {|f|
        elements = [(prefix unless prefix.empty?), f.name]
        name = elements.compact.join ','
        entry = get name
        if f.is_a? ProtocolBuffers::Field::MessageField
          recursive_entries(f.proxy_class, prefix: name, list: list)
        elsif f.repeated?
          get(name).each {|i| list << ["#{[name, i].join ','}", f] }
        else
          # p [:recursive_entries, :else, f.name, f]
          list << [name, f]
        end
      }
      list
    end

    # Canonical items that are in everyone's game - excludes generated creatures
    def normal_items x = nil
      recursive_entries(x).map {|nm, f| nm }.reject {|x| x =~ /(DEMON|FORGOTTEN_BEAST|NIGHT_CREATURE|TITAN|DIVINE)_\d+(:|$)/i }
    end

    def all_entries x = nil
      recursive_entries(x).map {|nm, f| nm }
    end

    def all_items   x = nil
      recursive_entries(x).select {|nm, f|  f.repeated? }.map {|nm, f| nm }
    end

    def all_options x = nil
      recursive_entries(x).select {|nm, f| !f.repeated? }.map {|nm, f| nm }
    end

    # By path, eg: 'food,plants,wheat'
    def get path
      elements = path.split ','
      name = elements.pop
      prefix = elements.join ','
      last = prefix.split(',').inject(pile) {|stock, nm| stock.send nm }
      last.is_a?(ProtocolBuffers::RepeatedField) ? last.include?(name) : last.send(name)
    end

    # set('food,prepared_meals', true)
    def set path, v = true
      elements = path.split ','
      name = elements.pop
      prefix = elements.join ','
      get(prefix).send("#{name}=", v)
      get path
    end

    #    add('food,meat,POND_GRABBER_SPLEEN')
    def    add path, item = nil
      elements = path.split ','
      item ||= elements.pop
      prefix = elements.join ','
      get(prefix) << item
      get([prefix, item].join ',')
    end
    # remove('food,meat,POND_GRABBER_SPLEEN')
    def remove path, item = nil
      elements = path.split ','
      item ||= elements.pop
      prefix = elements.join ','
      get(prefix).delete item
    end
    
    def to_s ; pile.to_s end

    def inspect
      "#<#{self.class.name}:#{'0x' + hash.to_s(16)} #{pile.to_s.length} bytes>"
    end

    attr_reader :pile

    def initialize stockpile: nil, stockfile: nil
      @pile = if stockfile
        self.class.read_stockfile stockfile
      elsif stockpile.is_a? stockpile_prototype
        self.class.decode_stock stockpile.to_s
      elsif stockpile # What else could it be?
        raise "ArgumentError - What's #{stockpile}?"
      else
        stockpile_prototype.new
      end
    end
  end

  # bars/iron
  # furniture/tables/masterwork/iron
  # food/prepared
  # seeds/plump-helmet
  # Is Stock a specific thing, or a class of things?
  # Can two stock-types be combined? table/iron AND table/rock?
  # Can types be subtracted? table/rock - table/obsidian - table/masterwork
  # Are modifiers a thing which can be added removed?
  # table + masterwork
  # Are All and None special?
  # All - table/iron/masterwork
  # class Stock
  #   def includes stock
  #     return false if type == :none
  #     return true  if type == :all
  #     return true  if type == stock
  #   end
  #   attr_reader :type
  #   def initialize type, quality = nil
  #     @type = type
  #   end
  # end

end
