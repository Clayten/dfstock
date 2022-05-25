module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module OrganicCategory
    def material_info type, index ; df::MaterialInfo.new type, index end

    def mat_table ; df.world.raws.mat_table end

    def organic_types cat_name
      cat_num = DFHack::OrganicMatCategory::NUME[cat_name]
      raise "Unknown category '#{cat_name.inspect}'" unless cat_num
      cache(:organics) {
        mat_table.organic_types.each_with_index.map {|ot,i| ot.zip mat_table.organic_indexes[i] }
      }[cat_num]
    end
    def organic cat_name, index ; p [:o, cat_name, index] ; organic_types(cat_name)[index] end
  end

  module InorganicComparators2
    def is_gem?   ; material.flags[:IS_GEM] end
    def is_stone? ; material.flags[:IS_STONE] end
    def is_metal? ; material.flags[:IS_METAL] end

    def is_ore?  ; raw.flags[:METAL_ORE] end
    def is_soil? ; raw.flags[:SOIL] end

    def is_economic_stone?
      !is_ore? &&
      !is_metal? &&
      !is_soil? &&
      !raw.economic_uses.empty?
    end

    def is_clay?
       raw.id =~ /CLAY/ &&
      !raw.flags[:AQUIFER] &&
      !is_stone?
    end

    def is_other_stone?
       is_stone? &&
      !is_ore? &&
      !is_economic_stone? &&
      !is_clay? &&
      !material.flags[:NO_STONE_STOCKPILE]
    end
  end

  class Thing2
    # Organic-category based methods
    extend OrganicCategory

    # Comparators for inorganic items
    include InorganicComparators2

    def self.format_classname x = nil ; (x || self).to_s.split('::').last.downcase end
    def self.parentclasses    x = nil ; (x || self).ancestors.select {|x| x.is_a? Class }.select {|x| x.name =~ /DFStock/ } end
    def self.parentclass      x = nil ; pcs = parentclasses(x) ; p [:pcs, pcs] ; pcs[1] end

    # Only called once, at initial class definition - before anonymous class is assigned a name from its constant
    def self.inherited subclass
      p [:inherited, subclass]
      # subclassname    =              subclass.to_s.split('::').last.downcase
      # parentclassname = subclass.ancestors[1].to_s.split('::').last.downcase
      subclassname    = format_classname subclass
      parentclassname = format_classname parentclass
      subclass_index  = "#{subclassname}_index"
        parent_index  = "#{parentclassname}_index"
      subclass_ivar   = '@' + subclass_index

      p [subclassname, parentclassname, subclass_index, parent_index, subclass_ivar]
      subclass.define_method(:initialize) {|index, link: nil|
        instance_variable_set subclass_ivar, index
        p [:initialize, :self, self.class, :level, subclassname, :index, index, :parent, parentclassname, parent_index, send(parent_index), :link?, !!link]
        super send(parent_index), link: link
      }

      # Define the accessor and the alias
      subclass.define_method(subclass_index) { instance_variable_get subclass_ivar }
      subclass.define_method(        :index) { send                  subclass_index }

      subclass.define_method(:to_s) { super() + " #{subclass_index}=#{send subclass_index}" }

      # Thing doesn't modify the index, it uses whatever its direct child uses
      # Direct descendants don't need to specify a parent linkage because of this method
      if parentclassname == 'thing2'
        p [:def_method, :thing2_index, :to, subclass_index]
        subclass.define_method("#{parentclassname}_index") { p [:thing2_index, :sending, subclass_index] ; send subclass_index }
      end
    end

    # Scaffold a linkage to an organic_mat_category and via inheritance, a type hierarchy. Thing -> Plant -> Leaf, etc.
    def self.category_based cat
      parentclassname = format_classname parentclass
      selfclassname   = format_classname

      metaclass = (class << self ; self ; end)

      # Class methods
      metaclass.define_method("#{selfclassname}_category") { cat }
      metaclass.define_method("#{selfclassname}_types") { organic_types(send "#{selfclassname}_category") }
      metaclass.define_method("#{selfclassname}_infos") { send("#{selfclassname}_types").map {|t,i| material_info(t,i) } }
      metaclass.define_method("#{selfclassname}_raws")  { send("#{selfclassname}_infos").map &:plant }

      # Create a hook to find an instance's index based on its raw, for child-classes to link through
      define_method("#{selfclassname}_by_raw") {|raw| self.class.send("#{selfclassname}_raws").index raw }

      # Using the Parent.parent_by_raw method, if it exists, to provide the Self.parent_index method
      if parentclass.instance_methods.include?("#{parentclassname}_by_raw".to_sym)
        define_method("#{parentclassname}_index") {
          send "#{parentclassname}_by_raw", raw
        }
      end

      # # These could be put on Plant2
      # # The basic accessors
      # define_method(:raw)       { self.class.send("#{selfclassname}_infos")[send "#{selfclassname}_index"].plant }
      # define_method(:material)  { self.class.send("#{selfclassname}_infos")[send "#{selfclassname}_index"].material }

      # define_method(:materials) { raw.material }
      # define_method(:growths)   { raw.growths }
      # define_method(:growth)    { growths.find {|g| g.str_growth_item.include? material.id } }
    end

    # Scaffold a linkage to an organic_mat_category and via inheritance, a type hierarchy. Thing -> Plant -> Leaf, etc.
    def self.inorganic_subset &discriminator
      parentclassname = format_classname parentclass
      selfclassname   = format_classname

      metaclass = (class << self ; self ; end)
      p [:inorganic_subset, :self, self, :name, selfclassname, :parentname, parentclassname, :meta, metaclass]

      metaclass.define_method("#{format_classname}_raws") { df.world.raws.inorganics.select {|i| discriminator[i] } }

    end

    # Caching
    def self.internal_cache ; @@cache ||= Hash.new {|h,k| h[k] = {} } end
    def self.clear_cache   ; internal_cache.clear end
    def self.inspect_cache ; internal_cache end
    def self.cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      internal_cache[cache_id] = yield
    end
    def cache *cache_id, &b ; self.class.cache([cache_id, :instance], &b) end

    # Utility
    def title_case string ; string.split(/\s+/).map(&:downcase).map(&:capitalize).join(' ') end

    # Linkage
    def linked? ; !@link.nil? end
    def enabled? ; !!@link[link_index] end

    # Base methods
    def token ; 'NONE' end

    def to_s ; "#{self.class.name} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} token=#{token.inspect}" end
    def inspect ; "#<#{to_s}>" rescue super end

    attr_accessor :link_index
    attr_accessor :link
    def initialize index, link: nil
      raise "You can't instantiate the base class" if self.class == Thing2
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @link_index = index
      @link = link
    end
  end

  class Inorganic2 < Thing2

    def self.inorganic2_raws ; df.world.raws.inorganics end
    def self.inorganic2 ; end

    def thing2_index ; inorganic2_index end
    def raw ; self.class.inorganic2_raws[inorganic2_index] end
    def material ; raw.material end
    def materials ; [material] end # There's only one

    inorganic_subset {|x| true }
  end

  class Stone2 < Inorganic2
    inorganic_subset {|x| x.is_stone? }
  end

  class Ore2 < Inorganic2
    inorganic_subset {|x| x.is_ore? }
  end

  class Plant2 < Thing2
    category_based :Plants

    def raw       ; p [:scn, self.class.format_classname, self.class.fruitleaf2_infos.length, fruitleaf2_index] ;  self.class.send("#{self.class.format_classname}_infos")[send "#{self.class.format_classname}_index"].plant end
    def material  ; self.class.send("#{self.class.format_classname}_infos")[send "#{self.class.format_classname}_index"].material end
    def materials ; raw.material end
    def growths   ; raw.growths end
    def growth    ; growths.find {|g| g.str_growth_item.include? material.id } end

    def token ; title_case raw.name end
  end

  class FruitLeaf2 < Plant2
    category_based :Leaf
    # parent_by_raw

    def token ; title_case "#{growth.name}" end
  end

  class PlantPowder2 < Plant2
    category_based :PlantPowder
    # parent_by_raw

    def token ; title_case material.state_name[:Powder] end
  end


  module RawMaterials
    def materials ; return [] unless respond_to? :raw ; r = raw rescue false ; return [] unless r ; r.material.to_a end # NOTE: Redefine as appropriate in the base-class when redefining material.
    def material  ; materials.first if materials end
    def raws ; return false unless raw ; raw.raws.sort end
    def raw ; raise "#{self.class} does not have a raw definition" end
    def has_raw?      ; !!(raw      rescue nil) end
    def has_material? ; !!(material rescue nil) end

    def material_ids ; materials.map &:id end

    def active_flags ms ; ms = [*ms] ; Hash[ms.map(&:flags).inject({}) {|a,b| a.merge Hash[b.to_hash.select {|k,v| v }] }.sort_by {|k,v| k.to_s }] end
    def mfah ; materials.inject({}) {|h,m| h[m.id] = active_flags m ; h } end
    def material_flags ms = nil
      return {} unless has_material?
      active_flags(ms || materials)
    end
    def raw_flags
      return {} unless has_raw?
      active_flags([raw])
    end
  end

  class Thing
    include RawMaterials

    def self.material_info cat, id ; df::MaterialInfo.new cat, id end
    def self.material cat, id ; material_info(cat, id).material end # FIXME How to create the material directly?

    def self.mat_table ; df.world.raws.mat_table end
    def self.organic_mat_categories ; DFHack::OrganicMatCategory::NUME.keys end
    def self.organic_category cat_name ; cat_name.is_a?(Numeric) ? cat_name : DFHack::OrganicMatCategory::NUME[cat_name] end
    def self.organic_types ; cache(:organics) { mat_table.organic_types.each_with_index.map {|ot,i| ot.zip mat_table.organic_indexes[i] } } end
    def self.organic cat_name, index # eg: (:Fish, 34) -> Creature_ID, Caste_ID
      cat_num = organic_category cat_name
      raise "Unknown category '#{cat_name.inspect}'" unless cat_num
      organic_types[cat_num][index]
    end

    # For a class, call the method that lists all of its instances
    def self.instances
      # Downcase and pluralize the classname
      nm = self.name.split(':').last.downcase
      plural_forms = [
        nm,                   # fish    -> fish
        (nm + 's'),           # tree    -> trees
        (nm + 'es'),          # glass   -> glasses
        (nm.sub(/f$/,'ves')), # leaf    -> leaves
        (nm.sub(/y$/,'ies'))  # quality -> qualities
      ]
      plural_forms.each {|mn|
        return send(mn) if respond_to?(mn)
      }
      false
    end

    def self.[] n
      n = n.source if n.respond_to? :source
      t = Regexp.new n, Regexp::IGNORECASE
      instances.select {|i| i.token =~ t }
    end

    # List all classes descended from this one
    def self.subclasses
      ObjectSpace.each_object.select {|o| o.is_a?(Class) && o < self }.sort_by(&:to_s)
    end

    private
    def food_indexes *ms ; ms.flatten.inject([]) {|a,m| fmis = m.food_mat_index.to_hash.reject {|k,v| -1 == v } ; a << [m.id, fmis] unless fmis.empty? ; a } end

    # Capitalize Every Word Of A String
    def title_case string ; string.split(/\s+/).map(&:downcase).map(&:capitalize).join(' ') end

    public

    def food_mat_indexes ; food_indexes *materials end

    def check_index
      raise "No linked array" unless link
      raise "Linked array is empty - did you enable the category?" if link.empty?
      raise "Index #{link_index} is out of array bounds (0 ... #{link.length})" unless (0 ... link.length) === link_index
    end
    def set x ; check_index ; link[link_index] = !!x end
    def get   ; check_index ; link[link_index] end
    def  enabled? ; !!get end
    def  enable   ; set true end
    def disable   ; set false end
    def  toggle   ; set !enabled? end

    def  tile_color     ; material.tile_color  if material end
    def build_color     ; material.build_color if material end
    def basic_color     ; material.basic_color if material end
    def state_color     ; material.state_color if material end
    def state_color_str ; material.state_color_str.to_hash.reject {|k,v| v.empty? } if material end
    def colors ; [:tc, tile_color, :buc, build_color, :bac, basic_color, :sc, state_color, :scs, state_color_str] end
    def color
      fore, back, bright = tile_color.to_a
      fore, bright = basic_color.to_a
      color_definitions[[fore, bright]]
    end

    def color_definitions
      {[0,0] => :black,       [0,1] => :dark_gray,
       [1,0] => :blue,        [1,1] => :light_blue,
       [2,0] => :green,       [2,1] => :light_green,
       [3,0] => :cyan,        [3,1] => :light_cyan,
       [4,0] => :red,         [4,1] => :light_red,
       [5,0] => :magenta,     [5,1] => :light_magenta,
       [6,0] => :brown,       [6,1] => :yellow,
       [7,0] => :light_gray,  [7,1] => :white
      }
    end

    # Cache lookups - this is pretty important for performance
    # @@cache = Hash.new {|h,k| h[k] = {} } unless @@cache if class_variables.include? :@@cache
    def self.internal_cache ; @@cache ||= Hash.new {|h,k| h[k] = {} } end
    def self.cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      internal_cache[cache_id] = yield
    end
    def internal_cache ; self.class.internal_cache end
    def cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      internal_cache[cache_id] = yield
    end
    def self.clear_cache   ; internal_cache.clear end
    def self.inspect_cache ; internal_cache end

    def token ; 'NONE' end
    def to_s ; "#{self.class.name} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} token=#{token.inspect}" end
    def inspect ; "#<#{to_s}>" rescue super end

    def link ; @link end
    def linked? ; link && !link.empty? end

    def self.classname
      name.to_s.split(/:/).last.downcase
    end
    def self.index_translation
      send(classname + '_indexes')
    end

    def == o ; self.class == o.class && index == o.index end

    attr_reader :base_index
    alias link_index base_index # override if necessary
    def initialize index, link: nil
      raise "You can't instantiate the base class" if self.class == Thing
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @base_index = index
      @link = link
    end
  end

  # # Template
  # class X < Thing ; end
  # class Y < X
  #   def self.Y_indexes ; (0 ... ??.length).to_a end
  #   def self.index_translation ; Y_indexes end # Scaffolded automatically, if your classname matches Y from Y_indexes
  #
  #   def x_index ; self.class.Y_indexes[Y_index] end
  #   def token ; title_case "xyz" end # Varies by class
  #   def to_s ; super + " Y_index=#{Y_index}" end
  #
  #   attr_reader :y_index
  #   alias index y_index
  #   alias link_index index # If necessary
  #   def initialize index, link: nil
  #     @y_index = index
  #     super x_index, link: link
  #   end
  # end

end
