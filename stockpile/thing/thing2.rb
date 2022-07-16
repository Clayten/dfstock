require 'comparators2'
require 'categories2'

module DFStock

  # A Stock 'Thing' is a bit conceptual, as I'm modelling quality levels that way as well as items
  # mostly though, things are a plant, or are made of a plant material, for example. One is a plant raw, the other a plant material.
  # A plant raw is the plant definition, will often include many materials, each of which will be stockpiled differently, seeds vs berries, etc.
  # As such, material questions about a conceptual strawberry plant are necessarily a bit ambiguous.

  class Thing2
    # Comparators
    include          Comparators2
    include     PlantComparators2
    include   BuiltinComparators2
    include  CreatureComparators2
    include InorganicComparators2

    # Category Definitions
    extend   BuiltinCategory
    extend   OrganicCategory
    extend InorganicCategory
    extend  CreatureCategory
    extend      ItemCategory
    # Scaffolds
    extend StockScaffold

    def self.format_classname x = nil ; (x || self).to_s.split('::').last.downcase end
    def self.parentclasses    x = nil ; c = x || self ; c.ancestors.select {|x| x.is_a? Class }.select {|x| x.name =~ /DFStock/ } end
    def self.parentclass      x = nil ; pcs = parentclasses(x) ; pcs[1] end


    # Only called once, at initial class definition - before anonymous class is assigned a name from its constant
    def self.inherited subclass
      raise "Improper inheritence" unless subclass < self
      subclassname    = format_classname subclass
      parentclassname = format_classname parentclass subclass
      subclass_index  = "#{subclassname}_index"
        parent_index  = "#{parentclassname}_index"

      # p :_
      # p [:inherited, subclass, :from, self, :parent, parentclass(subclass), :nm, subclassname, :pn, parentclassname]

      raise "This method uses the classname to scaffold accessors and can't be used by unnamed classes: #{subclassname}" if subclassname =~ /:/

      subclass.class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def initialize idx = nil, link: nil, raw: nil, material: nil, type: nil
          # p [:initialize_sub, :klass, self.class, :self, :#{subclassname}, :index, idx, :raw_override, !!raw, :link, !!link]
          raise "Incorrect usage, specify an index OR a raw/material/type" if idx && (raw || material || type)

          @#{subclass_index} = idx
          # Overrides for testing
          @raw      = raw      if raw
          @material = material if material
          @type     = type     if type

          super idx, link: link
        end

        def self.num_instances ; send(%w(raws materials types).find {|mn| respond_to? mn }).length end
        def self.instances     ; cache([:instances, #{subclass}]) { num_instances.times.map {|i| new i } } end

        # Define the accessor and the alias
        attr_reader :#{subclass_index}
        alias index #{subclass_index}

        # Add to the description
        def to_s ; super + " #{subclass_index}=" + #{subclass_index}.to_s end
      TXT
    end

    def self.subclasses ; ObjectSpace.each_object.select {|o| o.is_a?(Class) && o < self }.sort_by(&:to_s) end

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
    def  enable   ; set true end
    def disable   ; set false end
    def  toggle   ; set !enabled? end

    def self.[] n
      n = n.source if n.respond_to? :source
      t = Regexp.new n, Regexp::IGNORECASE
      instances.select {|i| i.token =~ t }
    end

    # Base methods
    def token ; 'NONE' end

    def raw       ; @raw      || (@material ? nil : (self.class.raws[index] if self.class.respond_to?(:raws))) end
    def material  ; @material || self.class.respond_to?(:materials) ? self.class.materials[index] : ([*raw.material].first if has_raw?) end

    def has_raw?      ; !!(@raw      || raw      rescue false) end
    def has_material? ; !!(@material || material rescue false) end

    def materials ; ms = has_raw? ? raw.material : material ; [*ms] end

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

    # Instead of an inheritance-based class structure this finds each class that wraps the same data and the index-number it uses
    def references
      id = [:references, *([:raw, raw._memaddr] if raw || [:material, material._memaddr] if material || [:type, type] if respond_to?(:type))]
      cache(id) {
        Thing2.subclasses.map {|sc|
          next unless idx =
            if    sc.respond_to? :raws                            ; sc.raws.index raw
            elsif sc.respond_to? :materials                       ; sc.materials.index material
          # elsif sc.respond_to?(:types)    && respond_to?(:type) ; sc.types.index type
            end
          [sc, idx]
        }.compact
      }
    end
    def to_s
      refs = references.map {|sc, idx| next if sc == self ; "#{self.class.format_classname sc}_index=#{idx}" }.compact.join(' ')
      "#{self.class.name} token=#{token.inspect} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} " +
      "#{"#{refs} " unless refs.empty?}link_index=#{link_index}"
    end
    def inspect ; "#<#{to_s}>" rescue super end

    # Only for xyz_index, looks up class XYZ in references and fetches that classes index for this raw/material/thing
    def method_missing mn, *args
      super unless mn =~ /_index/
      klassname = mn[0...mn.to_s.index('_index')]
      klass, index = references.find {|klass, _| self.class.format_classname(klass) == klassname }
      return index if klass
      super
    end

    attr_accessor :link_index # alias a later index over this to change what array is indexed into
    def initialize index, link: nil
      # p [:initialize_base, :klass, self.class, :index, index, :link, !!link]
      raise "You can't instantiate the base class" if self.class == Thing2
      return true if (@raw || @material || @type) && index.nil?
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @link_index = index
      @link = link
    end
  end

end

# FIXME - for rerunning inheritance during testing
def reinherit ks = nil
  ks ||= ObjectSpace.each_object(Class).select {|k| k < DFStock::Thing2 }.sort_by {|k| k.ancestors.length }
  # p [:ks, ks]
  ks.each {|k|
    kp = k.ancestors[1]
    # p [:kp, kp, :<=, :k, k]
    kp.inherited k
  }
end
def ccache ks = nil
  ks ||= ObjectSpace.each_object(Class).select {|k| k < DFStock::Thing2 }.sort {|a,b| a <=> b || 0 }.reverse
  # p [:ks, ks]
  ks.each {|k| k.clear_cache }
end
def try &b ; r = wrap &b ; puts(r.backtrace[0..12],'...',r.backtrace[-12..-1]) if r.is_a?(Exception) ; r end
def wrap ; r = nil ; begin ; r = yield ; rescue Exception => e ; $e = e ; end ; r || e end
