module DFStock
  module Scaffold
    # This runs at load-time
    def add_array desired_name, actual_name = desired_name, &initializer
      array = [self, desired_name, actual_name, initializer]
      # p [:add_array, array]
      @arrays ||= []
      @arrays.delete_if {|kl, dn, an, _| self == kl && desired_name == dn && actual_name == an }
      @arrays.push(array)
    end

    # This runs slightly later, at inclusion
    def included klass
      p [:included, self, klass]
      features = @arrays.select {|kl,_,_,_|
        kl == self
      }.map {|_,dn,an,i|
        [dn, an, i]
      }
      p [:features, features]

      features.each {|desired_name, actual_name, initializer|
        # p [:add_array, desired_name, actual_name]
        if desired_name == actual_name
          original_name = "original_#{desired_name}"
          # p [:checking, original_name]
          if !method_defined? original_name
            # p [:aliasing, original_name, :for, klass]
            klass.class_eval "alias #{original_name} #{actual_name}" unless klass.method_defined?(original_name)
            # p [:undef_method, actual_name, :on, klass]
            klass.class_eval { undef_method actual_name }
          end
        end
        # p [:define_methods, desired_name, klass]
        klass.send(:define_method, desired_name) {|&b|
          # p [:array_method, desired_name, (original_name || actual_name)]
          @count ||= 0
          send(original_name || actual_name).each_with_index.map {|v,idx|
            @count += 1
            # raise if @count > 5
            link = send(original_name || actual_name)
            # p [:index, idx, :link, link.class]
            # p caller
            obj = instance_exec(idx, link: link, &initializer)
          }
        }
      }
    end
  end
end

module DFStock
  module AnimalMod
    extend Scaffold
    add_array(:animals, :enabled) {|idx, link:| Creature.new  idx, link: link }
  end

  module FurnitureMod
    extend Scaffold
    add_array(:type)              {|idx, link:| Furniture.new idx, link: link }
    add_array(:quality_core)      {|idx, link:| Quality.new   idx, link: link }
    add_array(:quality_total)     {|idx, link:| Quality.new   idx, link: link }
  end
end

module DFStock
  class Thing
    def  enabled? ; link[id] end
    def  enable   ; link[id] = true  end
    def disable   ; link[id] = false end
    def set   x   ; x ? enable : disable end

    def to_s ; "#{self.class.name}:#{'0x%016x' % object_id } @id=#{id}#{" @link=#{link.class}" if link}" end
    def inspect ; "#<#{to_s}>" rescue super end

    attr_reader :id, :link
    def initialize id, link: nil
      @id       = id
      @link     = link
    end
  end

  class Creature < Thing
    def self.find_creature id ; creature = df.world.raws.creatures.all[id] end

    def edible?           ; true end # What won't they eat? Lol! FIXME?
    def lays_eggs?        ; creature.caste.any? {|c| c.flags.to_hash[:LAYS_EGGS] } end # Finds male and female of egg-laying species
    def grazer?           ; creature.caste.any? {|c| c.flags.to_hash[:GRAZER] } end
    def produces_honey?   ; creature.material.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } end
    def provides_leather? ; creature.material.any? {|mat| mat.id == 'LEATHER' } end

    def token ; creature.creature_id end
    def to_s ; "#{super} @creature_id=#{id} @caste_id=#{caste_id} token=#{token}" end

    attr_reader :caste_id, :creature, :caste
    def initialize id, caste_id: 0, link: nil
      super id, link: link
      @caste_id = caste_id
      @creature = self.class.find_creature id
      raise RuntimeError, "Unknown creature id: #{id}" unless creature
      @caste    = creature.caste[caste_id]
    end
  end

  class Furniture < Thing
    def self.find_furniture id ; DFHack::FurnitureType::ENUM[id] end

    def token ; @furniture end
    def to_s ; "#{super} @furniture_id=#{id} token=#{token}" end

    attr_reader :furniture
    def initialize id, link: nil
      super id, link: link
      @furniture = self.class.find_furniture id
      raise RuntimeError, "Unknown furniture id: #{id}" unless furniture
    end
  end


  class Quality < Thing
    def self.find_quality id ; DFHack::ItemQuality::ENUM[id] end

    def token ; @quality end
    def to_s ; "#{super} @quality_id=#{id} token=#{token}" end

    attr_reader :quality
    def initialize id, link: nil
      super id, link: link
      @quality = self.class.find_quality id
      raise RuntimeError, "Unknown quality level: #{id}" unless quality
    end
  end

end
class DFHack::StockpileSettings_TAnimals   ; include DFStock::AnimalMod end
class DFHack::StockpileSettings_TFurniture ; include DFStock::FurnitureMod end


# module DFStockMod
#   # Common to all types of stock
#   class StockThing
#     def  enable ; link.enable  id end
#     def disable ; link.disable id end
#     def set   x ; x ? enable : disable end
#
#     def to_s ; "#{self.class.name}:#{'0x%016x' % object_id } @id=#{id}#{" @link=#{link.class}" if link}" end
#     def inspect ; "#<#{to_s}>" rescue super end
#
#     attr_reader :id, :link
#     def initialize id, link: nil
#       @id       = id
#       @link     = link
#     end
#   end
#
#   def add_array enm, nm = enm
#     define_method("each_#{enm}") {|&b|
#       send(nm).each_with_index {|v,idx|
#         obj = yield idx
#         b[obj,v,idx]
#       }
#     }
#     define_method("get_#{enm}") {|x|
#       send(nm)[x]
#     }
#     define_method("set_#{enm}") {|x,v|
#       send(nm)[x] = !!v
#     }
#   end
# end
#
# module DFStockFurnitureMod
#   extend DFStockMod
#
#   class Furniture < DFStockMod::StockThing
#     def token ; @furniture end
#
#     def to_s ; "#{super} @furniture_id=#{id} token=#{token}" end
#
#     attr_reader :furniture
#     def initialize id, link: nil
#       super id, link: link
#       @furniture = DFStockFurnitureMod.find_furniture id
#       raise RuntimeError, "Unknown furniture id: #{id}" unless furniture
#     end
#   end
#
#   def find_furniture id ; creature = DFHack::FurnitureType::ENUM[id] end
#   def find_quality   id ; DFHack::ItemQuality::ENUM[id] end
#
#   class Quality < DFStockMod::StockThing
#     def token ; @furniture end
#
#     def to_s ; "#{super} @furniture_id=#{id} token=#{token}" end
#
#     attr_reader :furniture
#     def initialize id, link: nil
#       super id, link: link
#       @quality = DFStockFurnitureMod.find_quality id
#       raise RuntimeError, "Unknown furniture id: #{id}" unless furniture
#     end
#   end
#
#   add_array(:type)                   {|idx| Furniture.new idx, link: type }
#   add_array(:mat,             :mats) {|idx| p [:new_mat, idx] }
#   add_array(:other_mat, :other_mats) {|idx| p [:new_other_mat, idx] }
#   add_array(:quality_core          ) {|idx| Quality.new idx, link: quality_core }
#   add_array(:quality_total         ) {|idx| Quality.new idx, link: quality_total }
#
#   extend self
# end
#
# class DFHack::StockpileSettings_TFurniture
#   include DFStockFurnitureMod
#   # include Enumerable
# end
#
#
#
#
# module DFStockAnimalsMod
#
#   class Creature < DFStockMod::StockThing
#     def edible?           ; true end # What won't they eat? Lol! FIXME?
#     def lays_eggs?        ; creature.caste.any? {|c| c.flags.to_hash[:LAYS_EGGS] } end # Finds male and female of egg-laying species
#     def grazer?           ; creature.caste.any? {|c| c.flags.to_hash[:GRAZER] } end
#     def produces_honey?   ; creature.material.any? {|mat| mat.reaction_product.str.flatten.include? 'HONEY' } end
#     def provides_leather? ; creature.material.any? {|mat| mat.id == 'LEATHER' } end
#
#     def token ; creature.creature_id end
#
#     def to_s ; "#{super} @creature_id=#{id} @caste_id=#{caste_id} token=#{token}" end
#
#     attr_reader :caste_id, :creature, :caste
#     def initialize id, caste_id: 0, link: nil
#       super id, link: link
#       @caste_id = caste_id
#       @creature = DFStockAnimalsMod.find_creature id # , caste
#       raise RuntimeError, "Unknown creature id: #{id}" unless creature
#       @caste    = creature.caste[caste_id]
#     end
#   end
#
#   def find_creature_and_caste id, caste
#     creature = df.world.raws.creatures.all[id]
#     caste = creature.caste[caste]
#     [creature, caste]
#   end
#
#   def find_creature id
#     p [:find_creature, id]
#     creature = df.world.raws.creatures.all[id]
#   end
#
#   def [] x
#     # p [:[], x]
#     enabled[x]
#   end
#
#   def []= x, y
#     # p ["[#{x}]=".to_sym, y]
#     enabled[x] = y
#   end
#
#   def enable x, value = true
#     case x
#     when Integer ; self[x] = value # Can this be handled via super?
#     when /^\d+/  ; self[x.to_i] = value
#     else ; each_creature {|id,val,c,index| m = id =~ /#{x}/ ; self[index] = value if m }
#     end
#   end
#
#   def disable x
#     enable x, false
#   end
#
#   def each_creature &b
#     e = enabled.to_a
#     return e unless b
#     e.each_with_index {|value, index|
#       # p [:ec, value, index]
#       # creature = df.world.raws.creatures.all[index]
#       # id = creature.creature_id # + ':' + caste.caste_id
#       creature = Creature.new index, link: self
#       b[creature.token, value, creature, index]
#     }
#   end
#
#   extend self
# end
#
# class DFHack::StockpileSettings_TAnimals
#   include DFStockAnimalsMod
#   # include Enumerable
# end
#
#
#
#
# module DFStockMod
#   # All lists and flags together, in one list of [cat:subcat:name,v] pairs. Or, just a list of 'c:s:n', and you query for the values? Is it only the true values?
#   def items
#   end
#
#   def - o
#     items = items.zip(o.items).map {|a,b| next unless a ; next if b ; a }
#   end
#
#   def + o
#     items = items.zip(o.items).map {|a,b| next unless a || b ; a }
#   end
# end
#
# class DFHack::BuildingStockpilest
# end
#
#
#
# # require 'protocol_buffers'
# #
# # class DwarfFortressUtils
# #
# #   # The goal is to toggle stock by specific item, by material, or by regex, and globally or in a category
# #   # Also, to toggle the flags (category X, allow plant, etc) and set the numeric options (wheelbarrows, etc)
# #   #
# #   # Also desired is a way to split a stockpile, to ensure that every item in the one is represented in two or more
# #   # piles that are intended to take from the first, cleanly separating goods.
# #   #
# #   # ex:
# #   # pile = Stockpile.new
# #   # pile.accept(/hammer/)
# #   # pile.accept(:weapons, type: [:wood!]) # not wood weapons...?
# #   # pile.forbid(/sword/, :food) # forbids swordferns from food, ignores :weapons category.
# #   #
# #   # modifiers - material, quality, ...?
# #
# #
# #   # The theoretical concept of a stockpile, not the physical implementation
# #   class Stockpile
# #
# #     # private
# #
# #     # Use the DFHack ProtocolBuffer protofile to define our base stockpile settings object
# #     def self.load_proto_description
# #       # return if Dfstockpiles::StockpileSettings rescue nil
# #       return true if const_defined?(:Dfstockpiles)
# #       load "#{File.dirname __FILE__}/stockpiles.pb.rb"
# #       # load "#{File.dirname __FILE__}/stockpiles_pb.rb"
# #     end
# #     load_proto_description
# #
# #     def self.stockpile_prototype
# #       Dfstockpiles::StockpileSettings
# #     end
# #
# #     def stockpile_prototype ; self.class.stockpile_prototype end
# #
# #     # Read material data by introspection of the running instance of DF
# #     # Things like - is_food, is_millable, etc.
# #     def self.read_dwarf_data
# #       # FIXME - implement
# #     rescue StandardError => e
# #       raise "Failure to read DF data. #{e.class} #{e.message}"
# #     end
# #
# #     public
# #
# #     def self.items
# #
# #     end
# #     def self.categories
# #       items.keys
# #     end
# #
# #     def self.decode_stock buf
# #       sp = Dfstockpiles::StockpileSettings.new
# #       sp.parse buf
# #       sp
# #     end
# #     def self.encode_stock stockpile
# #       stockpile.to_s
# #     end
# #
# #     def self.read_stockfile fn
# #       decode_stock File.read(fn, encoding: 'ASCII')
# #     end
# #     def self.write_stockfile sp, fn
# #       File.write fn, encode_stock(sp)
# #     end
# #
# #     def self.new_from_file fn
# #       new read_stockfile fn
# #     end
# #
# #     def self.new_from_buffer buf
# #       new decode_stockfile buf
# #     end
# #
# #     def write fn
# #       self.class.write_stockfile fn, to_s
# #     end
# #
# #     # goal - s.select {|i| i.food? } == s.food
# #     # s.enable 'PLANT:ELEPHANT-HEAD_AMARANTH:SEED' == s.enable 'Elephant-head amaranth' == s.items.each {|i| i.enable if i.name =~ /^Ele.*anth/ }
# #     #
# #     # S::Item
# #     # .quality? -> (min..max) ??
# #     # - Problem - items can't necessarily be composed into one stockpile if they have different qualities or materials - perhaps by unwanted broadening of the selection
# #     # -           other times this is what you want. s << 'food' << 'swords' - and it just works. But does it if it accepts too much?
# #     # - P       - Needs backlink to parent pile.
# #     #
# #     # Proposal: s.items.each {|i| s.enable i if i.name =~ /^Ele.*anth/ } - Lighter-weight perhaps.
# #     #
# #     #
# #
# #     def fields ; pile.fields.values end
# #     def field n ; fields.find {|f| f.name == n.to_sym } end
# #
# #     def flags      ; fields.select {|f| ProtocolBuffers::Field::BoolField === f }.map {|f| f.name } end
# #     def categories ; fields.select {|f| ProtocolBuffers::Field::MessageField === f }.map(&:name) end
# #
# #     def method_missing mn, *args, &b
# #       if fields.map(&:name).include? mn
# #         raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 0)" unless args.empty?
# #         return pile.send mn
# #       else
# #         raise NoMethodError, "undefined method `#{mn}' for #{inspect}"
# #       end
# #     end
# #
# #     # Categories can be enabled without any items selected - eg. a food stockpile that accepts nothing but still prevents spoilage
# #     # FIXME implement enable/disable - @set_fields?
# #     def  enable_category cats ; categories.each {|cat|  enable cat } end
# #     def disable_category cats ; categories.each {|cat| disable cat } end
# #
# #     # The counterpart to the method below
# #     # reports stored data from a maximal stockpile
# #     def all_possible_items ; end
# #
# #     # Will always include max_wheelbarrows even if zero, and use_links_only even if null, but will only include Wood types (etc) that are actually selected (added to the array)
# #     def recursive_entries x = nil, prefix: '', list: []
# #       x ||= pile
# #       # p [:recursive_entries, :x, x.class, :prefix, prefix, :list_length, list.length]
# #       x.fields.values.each {|f|
# #         elements = [(prefix unless prefix.empty?), f.name]
# #         name = elements.compact.join ','
# #         entry = get name
# #         if f.is_a? ProtocolBuffers::Field::MessageField
# #           recursive_entries(f.proxy_class, prefix: name, list: list)
# #         elsif f.repeated?
# #           get(name).each {|i| list << ["#{[name, i].join ','}", f] }
# #         else
# #           # p [:recursive_entries, :else, f.name, f]
# #           list << [name, f]
# #         end
# #       }
# #       list
# #     end
# #
# #     # Canonical items that are in everyone's game - excludes generated creatures
# #     def normal_items x = nil
# #       recursive_entries(x).map {|nm, f| nm }.reject {|x| x =~ /(DEMON|FORGOTTEN_BEAST|NIGHT_CREATURE|TITAN|DIVINE)_\d+(:|$)/i }
# #     end
# #
# #     def all_entries x = nil
# #       recursive_entries(x).map {|nm, f| nm }
# #     end
# #
# #     def all_items   x = nil
# #       recursive_entries(x).select {|nm, f|  f.repeated? }.map {|nm, f| nm }
# #     end
# #
# #     def all_options x = nil
# #       recursive_entries(x).select {|nm, f| !f.repeated? }.map {|nm, f| nm }
# #     end
# #
# #     # By path, eg: 'food,plants,wheat'
# #     def get path
# #       elements = path.split ','
# #       name = elements.pop
# #       prefix = elements.join ','
# #       last = prefix.split(',').inject(pile) {|stock, nm| stock.send nm }
# #       last.is_a?(ProtocolBuffers::RepeatedField) ? last.include?(name) : last.send(name)
# #     end
# #
# #     # set('food,prepared_meals', true)
# #     def set path, v = true
# #       elements = path.split ','
# #       name = elements.pop
# #       prefix = elements.join ','
# #       get(prefix).send("#{name}=", v)
# #       get path
# #     end
# #
# #     #    add('food,meat,POND_GRABBER_SPLEEN')
# #     def    add path, item = nil
# #       elements = path.split ','
# #       item ||= elements.pop
# #       prefix = elements.join ','
# #       get(prefix) << item
# #       get([prefix, item].join ',')
# #     end
# #     # remove('food,meat,POND_GRABBER_SPLEEN')
# #     def remove path, item = nil
# #       elements = path.split ','
# #       item ||= elements.pop
# #       prefix = elements.join ','
# #       get(prefix).delete item
# #     end
# #
# #     def self.token_to_id tok
# #       tokens[tok]
# #     end
# #
# #     def self.id_to_token _type = nil, _index = nil, type: nil, index: nil, food_index: nil
# #       type  ||= _type
# #       index ||= _index
# #       materials[type][index]
# #     end
# #
# #     def to_s ; pile.to_s end
# #
# #     def inspect
# #       "#<#{self.class.name}:#{'0x' + hash.to_s(16)} #{pile.to_s.length} bytes>"
# #     end
# #
# #     attr_reader :pile
# #
# #     def initialize stockpile: nil, stockfile: nil
# #       @pile = if stockfile
# #         self.class.read_stockfile stockfile
# #       elsif stockpile.is_a? stockpile_prototype
# #         self.class.decode_stock stockpile.to_s
# #       elsif stockpile # What else could it be?
# #         raise "ArgumentError - What's #{stockpile}?"
# #       else
# #         stockpile_prototype.new
# #       end
# #     end
# #   end
# #
# #   # bars/iron
# #   # furniture/tables/masterwork/iron
# #   # food/prepared
# #   # seeds/plump-helmet
# #   # Is Stock a specific thing, or a class of things?
# #   # Can two stock-types be combined? table/iron AND table/rock?
# #   # Can types be subtracted? table/rock - table/obsidian - table/masterwork
# #   # Are modifiers a thing which can be added removed?
# #   # table + masterwork
# #   # Are All and None special?
# #   # All - table/iron/masterwork
# #   # class Stock
# #   #   def includes stock
# #   #     return false if type == :none
# #   #     return true  if type == :all
# #   #     return true  if type == stock
# #   #   end
# #   #   attr_reader :type
# #   #   def initialize type, quality = nil
# #   #     @type = type
# #   #   end
# #   # end
# #
# # end
