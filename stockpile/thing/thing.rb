module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module RawMaterials
    def materials ; return [] unless respond_to? :raw ; r = raw rescue false ; return false unless r ; r.material.to_a end # NOTE: Redefine as appropriate in the base-class when redefining material.
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
      has_raw? ?  active_flags([raw]) : {}
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
      @link  = link
    end
  end

  # # Template
  # class X < Thing
  #   def self.X_indexes ; (0 ... ??.length).to_a end
  #   def self.index_translation ; X_indexes end # Scaffolded automatically, if your classname matches X from X_indexes
  #   def Y_index ; self.class.X_indexes[X_index] end
  #   def to_s ; super + " X_index=#{X_index}" end
  #   attr_reader :X_index
  #   def initialize index, link: nil
  #     @X_index = index
  #     super Y_index, link: link
  #   end
  # end

end
