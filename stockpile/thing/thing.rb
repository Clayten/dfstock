require 'comparators'
require 'categories'

module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  class Thing
    include Comparators
    extend Categories
    extend StockScaffold

    def self.format_classname x = nil ; (x || self).to_s.split('::').last.downcase end
    def self.parentclasses    x = nil ; c = x || self ; c.ancestors.select {|x| x.is_a? Class }.select {|x| x.name =~ /DFStock/ } end
    def self.parentclass      x = nil ; pcs = parentclasses(x) ; pcs[1] end

    def self.metaclass ; (class << self ; self end) end


    # Only called once, at initial class definition - before anonymous class is assigned a name from its constant
    def self.inherited subclass
      raise "Improper inheritence" unless subclass < self
      subclassname    = format_classname subclass
      parentclassname = format_classname parentclass subclass

      # p :_
      # p [:inherited, subclass, :from, self, :parent, parentclass(subclass), :nm, subclassname, :pn, parentclassname]

      raise "This method uses the classname to scaffold accessors and can't be used by unnamed classes: #{subclassname}" if subclassname =~ /:/

      subclass.class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        # Define the accessor and the alias
        attr_reader :#{subclassname}_index
        alias index #{subclassname}_index

        # Add to the description
        def to_s ; super + " #{subclassname}_index=" + #{subclassname}_index.to_s end

        def initialize idx = nil, **kw
          # p [:initialize_sub, :klass, self.class, :index, idx, :extra, kw.keys]
          raise "Incorrect usage, specify an index OR a raw/material/type" if idx && (kw[:raw] || kw[:material] || kw[:type])

          @#{subclassname}_index = idx

          kw.each {|k,v|
            # p [:kw_instance_variable_set, k, v.class]
            instance_variable_set(('@' + k.to_s), v)
          }
          # p [:initialize_sub2, :instance_variable, instance_variables]

          super(idx)
        end

        def self.num_instances ; send(%w(raws materials types).find {|mn| respond_to? mn }).length end
        def self.instances     ; cache([:instances, #{subclass}]) { num_instances.times.map {|i| new i } } end
      TXT
    end

    def self.subclasses ; ObjectSpace.each_object.select {|o| o.is_a?(Class) && o < self }.sort_by(&:to_s) end

    # Caching
    def self.internal_cache ; @@cache ||= Hash.new {|h,k| h[k] = {} } end
    def self.clear_cache   ; internal_cache.clear end
    def self.inspect_cache ; internal_cache end
    def self.cache *cache_id, &b
      cache_id = cache_id.first if cache_id.length == 1
      # p [:cache, cache_id, :contained?, internal_cache.include?(cache_id)]
      return internal_cache[cache_id] if internal_cache.include?(cache_id)
      # start_time = Time.now
      result = internal_cache[cache_id] = yield
      # duration = Time.now - start_time
      # puts "Cache[#{cache_id.inspect}] took #{'%1.4f' %duration}s"
      # result
    end
    def cache *cache_id, &b ; self.class.cache([cache_id, :instance], &b) end

    # Utility
    def title_case string ; string.split(/\s+/).map(&:downcase).map(&:capitalize).join(' ') end
    def self.material_info type, index ; df::MaterialInfo.new type, index end

    # Linkage
    def link ; @link end
    def linked? ; link && !link.empty? end

    def check_index
      raise "#{self.class}: No linked array" unless link
      raise "#{self.class}: Linked array is empty - did you enable the category?" if link.empty?
      raise "#{self.class}: Index #{link_index} is out of array bounds (0 ... #{link.length})" unless (0 ... link.length) === link_index
    end
    def set x ; check_index ; link[link_index] = !!x end
    def get   ; check_index ; link[link_index] end
    def  enabled? ; !!(get rescue false) end
    def disabled? ; !enabled? end
    def  enable   ; set true end
    def disable   ; set false end
    def  toggle   ; set !enabled? end

    def self.lookup_by_name n
      n = n.source if n.respond_to? :source
      t = Regexp.new n, Regexp::IGNORECASE
      instances.select {|i| i.name =~ t }
    end
    def self.[] n ; self.lookup_by_name n end

    def self.token_index ; cache([:token_index, self]) { Hash[*instances.map(&:token).each_with_index.map {|t,i| [t, i] }.flatten] } end

    # Base methods
    def name ; 'NONE' end

    def raw_token
      return unless has_raw?
      raw.class == DFHack::CreatureRaw ? raw.creature_id : raw.id
    end
    def material_token
      return unless has_material?
      material.id.empty? ? material.state_name.first : material.id
    end
    def token
      if    raw_token && material_token && !material_token.empty? ; "#{raw_token}:#{material_token}"
      elsif raw_token                                             ; "#{raw_token}"
      elsif              material_token && !material_token.empty? ; "#{material_token}"
      elsif respond_to?(:type) && type                            ; "#{type}"
      end
    end
    def pathname ; "#{@category_name}|#{@subcategory_name}|#{token}".upcase.gsub(/\s/,'_') end

    def raw       ; @raw      || (@material ? nil : (self.class.raws[index] if self.class.respond_to?(:raws))) end
    def material  ; @material || self.class.respond_to?(:materials) ? self.class.materials[index] : ([*raw.material].first if has_raw? && raw.respond_to?(:material)) end

    def has_raw?      ; !!(@raw      || raw      rescue false) end
    def has_material? ; !!(@material || material rescue false) end

    def materials
      ms =
        if has_raw? && raw.respond_to?(:material)
          raw.material
        elsif respond_to?(:material)
          material
        end
      [*ms]
    end

    # Instead of an inheritance-based class structure this finds each class that wraps the same data and the index-number it uses
    def references
      id = [:references, *(([:raw, raw._memaddr]          if raw) ||
                          ([:material, material._memaddr] if material) ||
                          ([:type, type]                  if respond_to?(:type)))]
      cache(id) {
        r = m = t = nil
        Thing.subclasses.map {|sc|
          # p [:ref, :id, id, :sc, sc, !!r, !!m, !!t]
          next unless idx =
            if    sc.respond_to? :raws_index                         ;      sc.raws_index[(r ||= raw      ; r._memaddr if r)]
            elsif sc.respond_to? :materials_index                    ; sc.materials_index[(m ||= material ; m._memaddr if m)]
            elsif sc.respond_to?(:types_index) && respond_to?(:type) ;     sc.types_index[ t ||= type]
            end
          [sc, idx]
        }.compact
      }
    end
    def to_s
      refs = references.map {|sc, idx| next if sc == self.class ; "#{self.class.format_classname sc}_index=#{idx}" }.compact.join(' ')
      "#{self.class.name} name=#{name.inspect} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} " +
      "#{"#{refs} " unless refs.empty?}link_index=#{link_index}"
    end
    def inspect ; "#<#{to_s}>" rescue super end

    def index_lookup index_name
      klassname = index_name[0...index_name.to_s.index('_index')]
      klass, index = references.find {|klass, _| self.class.format_classname(klass) == klassname }
      return index if klass
      raise "Index #{index_name} did not return a value for #{self.class}"
    end

    # Only for xyz_index, looks up class XYZ in references and fetches that class's index for this raw/material/thing
    def method_missing mn, *args
      return index_lookup(mn) if mn =~ /_index/
      super
    end

    attr_accessor :link_index # redefine this to call another index if needed
    def initialize index
      # p [:initialize_base, :klass, self.class, :index, index]
      raise "You can't instantiate the base class" if self.class == Thing
      return true if (@raw || @material || @type) && index.nil?
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @link_index = index
    end
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
