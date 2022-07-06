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
    include InorganicComparators2

    # Category Definitions
    extend   OrganicCategory
    extend InorganicCategory
    # Scaffolds
    extend   OrganicScaffold
    extend InorganicScaffold

    def self.format_classname x = nil ; (x || self).to_s.split('::').last.downcase end
    def self.parentclasses    x = nil ; c = x || self ; c.ancestors.select {|x| x.is_a? Class }.select {|x| x.name =~ /DFStock/ } end
    def self.parentclass      x = nil ; pcs = parentclasses(x) ; pcs[1] end


    # Only called once, at initial class definition - before anonymous class is assigned a name from its constant
    def self.inherited subclass
      # p [:inherited, subclass, :from, self, subclass.ancestors]
      raise "Improper inheritence" unless subclass < self
      subclassname    = format_classname subclass
      parentclassname = format_classname parentclass subclass
      subclass_index  = "#{subclassname}_index"
        parent_index  = "#{parentclassname}_index"
      subclass_ivar   = '@' + subclass_index

      # p [:inherited, :scaffold_initialize, :sc, subclassname, :pc, parentclassname, :sc_i, subclass_index, :p_i, parent_index, :sc_iv, subclass_ivar]
#       subclass.define_method(:initialize) {|index, link: nil|
#         instance_variable_set subclass_ivar, index
#         # p [:initialize1, :self, self.class, :level, subclassname, :sciv, subclass_ivar, :index, index, :parent, parentclassname]
#         # p [:initialize2, :parent, parentclassname, parent_index, send(parent_index), :link?, !!link]
#         super send(parent_index), link: link
#       }
      subclass.class_eval(<<~INIT, __FILE__, __LINE__)
        def initialize index, link: nil
          @#{subclass_ivar} = index
          super #{parent_index}, link: link
        end
INIT

      # Define the accessor and the alias
      # subclass.define_method(subclass_index) { instance_variable_get subclass_ivar }
      subclass.class_eval(<<~IVAR, __FILE__, __LINE__)
        attr_reader :#{subclass_index}
      IVAR

      # subclass.define_method(        :index) { send                  subclass_index } # this gets overwritten in each child class
      subclass.class_eval(<<~INDEX, __FILE__, __LINE__)
        def index ; #{subclass_index} end
      INDEX

      # subclass.define_method(:to_s) { super() + " #{subclass_index}=#{send subclass_index}" }
      subclass.class_eval(<<~TO_S, __FILE__, __LINE__)
        def to_s ; super + " #{subclass_index}=" + #{subclass_index} end
      TO_S

      # Thing doesn't modify the index, it uses whatever its direct child uses
      # Direct descendants don't need to specify a parent linkage because of this method
      if parentclassname == 'thing2'
        # subclass.define_method("#{parentclassname}_index") {
        #   send subclass_index
        # }
        subclass.class_eval(<<~P_INDEX, __FILE__, __LINE__)
          def #{parentclassname}_index ; #{subclass_index} end
        P_INDEX
      end
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

    def to_s ; "#{self.class.name} token=#{token.inspect} linked=#{!!linked?}#{" enabled=#{!!enabled?}" if linked?} link_index=#{link_index}" end
    def inspect ; "#<#{to_s}>" rescue super end

    attr_accessor :link_index # alias a later index over this to change what array is indexed into
    def initialize index, link: nil
      # p [:initialize_thing, :klass, self.class, :index, index, :link, !!link]
      raise "You can't instantiate the base class" if self.class == Thing2
      raise "No index provided - invalid #{self.class} creation" unless index
      raise "Invalid index '#{index.inspect}'" unless index.is_a?(Integer) && index >= 0
      @link_index = index
      @link = link
    end
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
def ccache ks = nil
  ks ||= ObjectSpace.each_object(Class).select {|k| k < DFStock::Thing2 }.sort {|a,b| a <=> b || 0 }.reverse
  # p [:ks, ks]
  ks.each {|k| k.clear_cache }
end
def try &b ; r = wrap &b ; puts(r.backtrace[0..10],'...',r.backtrace[-10..-1]) if r.is_a?(Exception) ; r end
def wrap ; r = nil ; begin ; r = yield ; rescue Exception => e ; $e = e ; end ; r || e end
