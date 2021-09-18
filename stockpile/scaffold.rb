module DFStock

  # Code-generation to simplify describing the actual stockpile representing classes.
  # So many arrays of these things, so many flags, etc.

  module Scaffold
    # Scaffold is *extended* into a DFStock::TypeMod (eg. ArmorMod) *module*. It provides helper methods
    # similar to attr_accessor, add_array and add_flags, which define accessors to match the DF structures.
    #
    # This DFStock::TypeMod is then itself *included* into a DFHack::StockpileSettings_TType (eg _TArmor) *class*
    # where it build and binds the accessor code created previously.

    # This runs when Scaffold is *extended* into a DFStock:: *module* - it sets up the later parts
    def self.extended klass
      # p [:ext, self, :into, klass]
      klass.instance_variable_set(:@features, []) # Initialize the array, eliminate old definitions from previous loads
    end

    # This is called during class-definition at load-time
    def add_array stockklass, desired_name, actual_name = nil
      desired_name, actual_name = desired_name.to_sym, actual_name
      array = [:array, desired_name, actual_name, stockklass]
      # p [:add_array, self, :array, array]
      @features.delete_if {|type, dn, an, sk| type == :array && desired_name == dn && actual_name == an && stockklass = sk }
      @features.push(array)
      desired_name
    end

    # This is called during class-definition at load-time
    def add_flag desired_name, actual_name = nil
      flag = [:flag, desired_name, actual_name]
      # p [:add_flag, self, :flag, flag]
      @features.delete_if {|type, dn, an, _| type == :flag && desired_name == dn && actual_name == an }
      @features.push(flag)
      desired_name
    end

    # This runs when the DFStock *module* is *included* into a DFHack::StockpileSettings *class* - it creates the accessors
    #
    # Note: Unlike "most" modules, the accessors aren't defined on the module, this act of inclusion
    # triggers the manual creation of the accessors.
    def included klass
      # p [:included, :self, self, :into, klass, :features, @features.length, @features]

      # FIXME Change add method to take class as an argument, not hidden in a block
      # then query the class's index_translation table for size, rather than the
      # base array of flags.
      flags = []
      arrays = []
      @features.each {|type, desired_name, actual_name, stockklass|
        actual_name ||= desired_name
        if :flag == type
          base_name = "flag_#{actual_name}".to_sym
          flags << [desired_name, actual_name, base_name]
          if !method_defined? base_name
            klass.class_eval "alias #{base_name} #{actual_name}"
            klass.class_eval "alias #{desired_name} #{base_name}"
          end
          # p [:define_flag, :self, self, :klass, klass, :dn, desired_name, :bn, base_name, :an, actual_name]

        elsif :array == type
          base_name = "array_#{actual_name}".to_sym
          arrays << [desired_name, actual_name, base_name]
          if !klass.method_defined? base_name
            raise "Ack!" unless klass.instance_methods.include?(actual_name)
            klass.class_eval "alias #{base_name} #{actual_name}"
          end
          # p [:define_array, :self, self, :klass, klass, :dn, desired_name, :bn, base_name, :an, actual_name]
          klass.send(:define_method, desired_name) {|&b|
            flags_array = send base_name
            list = stockklass.index_translation # This is the reason this is a consistent class method
            array = list.each_with_index.map {|_, idx|
              stockklass.new idx, link: flags_array
            }
            def array.[]= i, v ; self[i].set !!v end
            array
          }

        else ; raise "Unknown type #{type}" end
      }

      klass.send(:define_method, :arrays) {
        desired_names = arrays.map {|desired_name, _, _| desired_name }
        pairs = desired_names.map {|desired_name| [desired_name, send(desired_name)] }.inject(&:+)
        Hash[*pairs]
      }
      klass.send(:define_method, :flags) {
        desired_names = flags.map {|desired_name, _, _| desired_name }
        pairs = desired_names.map {|desired_name| [desired_name, send(desired_name)] }.inject(&:+)
        Hash[*pairs]
      }
      features = @features.dup
      # p [:features, features]
      klass.send(:define_method, :features) { features }

      wrappers = arrays + flags
      wrapper_count = Hash.new {|h,k| h[k] = 0 }
      wrappers.each {|dn,an,bn| wrapper_count[an] += 1 }
      simple_wrappers, shared_wrappers = wrappers.partition {|dn, an, bn| wrapper_count[an] == 1 }

      simple_wrappers.each {|desired_name, actual_name, _|
        next if actual_name == desired_name
        klass.class_eval { undef_method actual_name }
        klass.class_eval "alias #{actual_name} #{desired_name}"
      }
      shared_wrappers.each {|desired_name, actual_name, base_name|
        wrapped_methods = wrappers.select {|d,a,b| a == actual_name }.map {|d,a,b| d }
        klass.class_eval { undef_method actual_name }
        klass.class_eval "def #{actual_name} ; #{wrapped_methods.join(' + ')} end"
      }
    end
  end

end
