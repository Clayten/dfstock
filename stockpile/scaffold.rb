module DFStock

  # Code-generation to simplify describing the actual stockpile representing classes.
  # So many arrays of these things, so many flags, etc.

  module Scaffold
    # Scaffold is *extended* into a DFStock::TypeMod (eg. ArmorMod) *module*. It provides helper methods
    # similar to attr_accessor, add_array and add_flags, which define accessors to match the DF structures.
    #
    # This DFStock::TypeMod is then itself *included* into a DFHack::StockpileSettings_TType (eg _TArmor) *class*
    # where it build and binds the accessor code created previously.
    #
    #
    # 
    # When you call 'extend X', X.extended(klassname) is called. The same with include/included().
    #
    # To use, create a DFStock::TypeMod module, where Type is the stockpile type. Stone, Food, etc.
    # Extend Scaffold, and use 'add_array' and 'add_flag' to describe the DF Stockpile.
    #
    #
    #
    # When a module is included it's .extended() method is called with class/module it's being included into
    # then 
    #

    # This runs when Scaffold is *extended* into a DFStock:: *module* - it sets up the later parts
    def self.extended klass
      p [:ext, self, :into, klass]
      klass.instance_variable_set(:@features, []) # Initialize the array, eliminate old definitions from previous loads
    end

    # This is called during class-definition at load-time
    def add_array stockklass, desired_name, actual_name = desired_name
      desired_name, actual_name = desired_name.to_sym, actual_name
      array = [:array, desired_name, actual_name, stockklass]
      p [:add_array, self, :array, array]
      @features.delete_if {|kl, dn, an, sk| self == kl && desired_name == dn && actual_name == an && stockklass = sk }
      @features.push(array)
      desired_name
    end

    # This is called during class-definition at load-time
    def add_flag desired_name, actual_name = desired_name
      flag = [:flag, desired_name, actual_name]
      @features.delete_if {|kl, dn, an, sk| self == kl && desired_name == dn && actual_name == an }
      @features.push(flag)
      desired_name
    end

    # This runs when the DFStock *module* is *included* into a DFHack::StockpileSettings *class* - it creates the accessors
    def included klass
      p [:included, self, :class, klass, :features, @features.length]

      # FIXME Change add method to take class as an argument, not hidden in a block
      # then query the class's index_translation table for size, rather than the
      # base array of flags.
      flags = []
      arrays = []
      @features.each {|type, desired_name, actual_name, stockklass|
        if :flag == type
          flags << desired_name
          next if desired_name == actual_name # no-op
          klass.class_eval "alias #{desired_name} #{actual_name}" unless klass.method_defined?(desired_name)
        elsif :array == type
          arrays << desired_name
          if desired_name == actual_name
            original_name = "original_#{desired_name}"
            if !method_defined? original_name
              klass.class_eval "alias #{original_name} #{actual_name}" unless klass.method_defined?(original_name)
              klass.class_eval { undef_method actual_name }
            end
          end

          flags_array_name = original_name || actual_name
          klass.send(:define_method, desired_name) {|&b|
            flags_array = send flags_array_name
            list = stockklass.index_translation # This is the reason this is a consistent class method
            list.each_with_index.map {|_, idx|
              stockklass.new idx, link: flags_array
            }
          }
        else
          raise "Unknown type #{type}"
        end
      }
      klass.send(:define_method, :arrays) { arrays.map {|a| send a } }
      klass.send(:define_method, :flags)  { flags }
    end
  end

end