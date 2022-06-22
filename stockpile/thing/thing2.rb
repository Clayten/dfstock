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

  module Raws2
    def has_raw? ; !!(raw rescue false) end
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
    # Category Definitions
    extend OrganicCategory

    # Comparators
    include Raws2
    include InorganicComparators2

    def self.format_classname x = nil ; (x || self).to_s.split('::').last.downcase end
    def self.parentclasses    x = nil ; c = x || self ; c.ancestors.select {|x| x.is_a? Class }.select {|x| x.name =~ /DFStock/ } end
    def self.parentclass      x = nil ; pcs = parentclasses(x) ; pcs[1] end

    # Only called once, at initial class definition - before anonymous class is assigned a name from its constant
    def self.inherited subclass
      # p [:inherited, subclass, :from, self, subclass.ancestors]
      raise "Improper inheritence" unless subclass < self
      # subclassname    =              subclass.to_s.split('::').last.downcase
      # parentclassname = subclass.ancestors[1].to_s.split('::').last.downcase
      subclassname    = format_classname subclass
      parentclassname = format_classname parentclass subclass
      subclass_index  = "#{subclassname}_index"
        parent_index  = "#{parentclassname}_index"
      subclass_ivar   = '@' + subclass_index

      # p [:inherited, :scaffold_initialize, :sc, subclassname, :pc, parentclassname, :sc_i, subclass_index, :p_i, parent_index, :sc_iv, subclass_ivar]
      subclass.define_method(:initialize) {|index, link: nil|
        instance_variable_set subclass_ivar, index
        # p [:initialize, :self, self.class, :level, subclassname, :sciv, subclass_ivar, :index, index, :parent, parentclassname, parent_index, send(parent_index), :link?, !!link]
        super send(parent_index), link: link
      }

      # Define the accessor and the alias
      subclass.define_method(subclass_index) { instance_variable_get subclass_ivar }
      subclass.define_method(        :index) { send                  subclass_index } # this gets overwritten in each child class

      subclass.define_method(:to_s) { super() + " #{subclass_index}=#{send subclass_index}" }

      # Thing doesn't modify the index, it uses whatever its direct child uses
      # Direct descendants don't need to specify a parent linkage because of this method
      if parentclassname == 'thing2'
        # p [:def_method, :thing2_index, :to, subclass_index]
        subclass.define_method("#{parentclassname}_index") {
          # p [:thing2_index, :sending, subclass_index]
          send subclass_index
        }
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

      metaclass.define_method("index_translation") { (0...send("#{selfclassname}_infos").length).to_a } # FIXME Can this be replaced with an int?

      # Create a hook to find an instance's index based on its raw, for child-classes to link through
      define_method("#{selfclassname}_by_raw") {|raw| self.class.send("#{selfclassname}_raws").index raw }

      # Using the Parent.parent_by_raw method, if it exists, to provide the Self.parent_index method
      if parentclass.instance_methods.include?("#{parentclassname}_by_raw".to_sym)
        define_method("#{parentclassname}_index") {
          send "#{parentclassname}_by_raw", raw
        }
      end
    end

    # Scaffold a linkage to an organic_mat_category and via inheritance, a type hierarchy. Thing -> Plant -> Leaf, etc.
    def self.inorganic_subset &discriminator
      parentclassname = format_classname parentclass
      selfclassname   = format_classname

      metaclass = (class << self ; self ; end)
      # p [:inorganic_subset, :self, self, :name, selfclassname, :parentname, parentclassname, :meta, metaclass]

      # def self.inorganic2_raws ; df.world.raws.inorganics end
      # def self.inorganics2 ; inorganic2_raws.each_with_index.map {|_,i| new i } end

      metaclass.define_method("#{format_classname}_raws") { inorganics2.select {|i| discriminator[i] } }

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
    def link ; @link end
    def linked? ; link && !link.empty? end

    def check_index
      raise "No linked array" unless link
      raise "Linked array is empty - did you enable the category?" if link.empty?
      raise "Index #{link_index} is out of array bounds (0 ... #{link.length})" unless (0 ... link.length) === link_index
    end
    def set x ; check_index ; link[link_index] = !!x end
    def get   ; check_index ; link[link_index] end
    def  enabled? ; !!(get rescue false) end
    def  enable   ; set true end
    def disable   ; set false end
    def  toggle   ; set !enabled? end

    # Base methods
    def token ; 'NONE' end

    def to_s ; "#{self.class.name} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} token=#{token.inspect}" end
    def inspect ; "#<#{to_s}>" rescue super end

    attr_accessor :link_index # alias a later index over this to change what array is indexed into
    def initialize index, link: nil
      raise "You can't instantiate the base class" if self.class == Thing2
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @link_index = index
      @link = link
    end
  end

  class Inorganic2 < Thing2
    inorganic_subset {|x| true }

    def self.inorganic2_raws ; df.world.raws.inorganics end
    def self.inorganics2 ; inorganic2_raws.each_with_index.map {|_,i| new i } end

    def self.instances ; inorganics2 end # scaffold
    def self.index_translation ; instances end # no scaffold?

    def raw ; self.class.inorganic2_raws[inorganic2_index] end
    def material ; raw.material end
    def materials ; [material] end # There's only one

    def token ; title_case material.state_name[:Solid] end
  end

  class Plant2 < Thing2
    category_based :Plants

    def raw       ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_infos")[idx].plant end
    def material  ; cn = self.class.format_classname ; idx = send "#{cn}_index" ; self.class.send("#{cn}_infos")[idx].material end
    def materials ; raw.material end

    # plant methods that should be on Thing
    def growths   ; has_raw? && raw.growths end
    def growth    ; growths.find {|g| g.str_growth_item.include? material.id } end

    def token ; title_case raw.name end

    def link_index ; index end
  end

  class Metal2 < Inorganic2
    inorganic_subset {|x| x.is_metal? }
  end

  class Stone2 < Inorganic2
    inorganic_subset {|x| x.is_stone? }
  end

  class Ore2 < Stone2
    inorganic_subset {|x| x.is_ore? }
  end

  class FruitLeaf2 < Plant2
    category_based :Leaf
    def token ; title_case "#{growth.name}" end
  end

  class PlantPowder2 < Plant2
    category_based :PlantPowder
    def token ; title_case material.state_name[:Powder] end
  end

end

# FIXME - for rerunning inheritance during testing
def reinherit ks = nil
  ks ||= ObjectSpace.each_object(Class).select {|k| k < DFStock::Thing2 }.sort {|a,b| a <=> b || 0 }.reverse
  # p [:ks, ks]
  ks.each {|k|
    kp = k.ancestors[1]
    # p [:kp, kp, :<=, :k, k]
    kp.inherited k
  }
end

