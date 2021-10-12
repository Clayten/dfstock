module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  module Raw
    def materials ; return [] unless respond_to? :raw ; raw.material.to_a end # NOTE: Redefine as appropriate in the base-class when redefining material.
    def material  ; materials.first end
    def raws ; return false unless raw ; raw.raws.sort end
  end

  module Material
    def material_ids ; materials.map &:id end
    def active_flags fs ; Hash[fs.inject({}) {|a,b| a.merge Hash[b.to_hash.select {|k,v| v }] }.sort_by {|k,v| k.to_s }] end
    def material_flags ms = materials ; ms = [*ms] ; cache(:material_flags, *ms.map(&:id)) { active_flags [*ms].map(&:flags) } end
  end

  class Thing
    include Raw
    include Material
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

    # For a class, list all of its instances
    def self.instances
      nm = self.name.split(':').last.downcase
      [
        nm,                   # fish    -> fish
        (nm + 's'),           # tree    -> trees
        (nm + 'es'),          # glass   -> glasses
        (nm.sub(/f$/,'ves')), # leaf    -> leaves
        (nm.sub(/y$/,'ies'))  # quality -> qualities
      ].each {|mn|
        return send(mn) if respond_to?(mn)
      }
      false
    end

    def self.subclasses
      ObjectSpace.each_object.select {|o| o.is_a?(Class) && o < self }.sort_by(&:to_s)
    end

    private
    def food_indexes *ms ; ms.flatten.inject([]) {|a,m| fmis = m.food_mat_index.to_hash.reject {|k,v| -1 == v } ; a << [m.id, fmis] unless fmis.empty? ; a } end

    def title_case string ; string.split(/\s+/).map(&:downcase).map(&:capitalize).join(' ') end

    public
    def food_mat_indexes ; food_indexes *materials end
    def check_index
      raise "No linked array" unless link
      raise "Linked array is empty - did you enable the category?" if link.empty?
      raise "Index #{index} is out of array bounds (0 ... #{link.length})" unless (0 ... link.length) === index
    end
    def set x ; check_index ; link[index] = !!x end
    def get   ; check_index ; link[index] end
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
    def to_s ; "#{self.class.name} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} token=#{token.inspect} index=#{index}" end
    def inspect ; "#<#{to_s}>" rescue super end

    def link ; @link end
    def linked? ; link && !link.empty? end

    def is_magma_safe?
      # p [:ims?, self, :material, material]
      return nil unless material && material.heat

      magma_temp = 12000
      mft = material.heat.mat_fixed_temp
      return true  if mft && mft != 60001

      cdp = material.heat.colddam_point
      return false if cdp && cdp != 60001 && cdp < magma_temp

      %w(heatdam ignite melting boiling).all? {|n|
        t = material.heat.send("#{n}_point")
        t == 60001 || t > magma_temp
      }
    end

    def self.classname
      name.to_s.split(/:/).last.downcase
    end
    def self.index_translation
      send(classname + '_indexes')
    end

    attr_reader :index
    def initialize index, link: nil
      raise "You can't instantiate the base class" if self.class == Thing
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @index = index # The index into the 'link'ed array for the thing
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
