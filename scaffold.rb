module DFStock

  # Code-generation to simplify describing the actual stockpile representing classes.
  # So many arrays of these things, so many flags, etc.

  module Scaffold
    # Scaffold is *extended* into a DFStock::TypeMod (eg. ArmorMod) *module*. It provides helper methods
    # similar to attr_accessor, add_array and add_flags, which define accessors to match the DF structures.
    #
    # This DFStock::TypeMod is then itself *included* into a DFHack::StockpileSettings_TType (eg _TArmor) *class*
    # where it build and binds the accessor methods listed previously with the helper methods.

    # This runs when Scaffold is *extended* into a DFStock:: *module* - it sets up the later parts
    def self.extended klass
      # p [:ext, self, :into, klass]
      klass.instance_variable_set(:@features, []) # Initialize the array, eliminate old definitions from previous loads
    end

    # This is called during class-definition at load-time
    def add_array stockklass, actual_name, desired_name = nil
      actual_name, desired_name = actual_name.to_sym, desired_name
      feature = [:array, actual_name, desired_name, stockklass]
      # p [:add_array, self, :feature, feature]
      @features.delete_if {|type, an, dn, sk| type == :array && actual_name == an && desired_name == dn && stockklass = sk }
      @features.push(feature)
      actual_name
    end

    # This is called during class-definition at load-time
    def add_flag actual_name, desired_name = nil
      feature = [:flag, actual_name, desired_name]
      # p [:add_flag, self, :feature, feature]
      @features.delete_if {|type, an, dn, _| type == :flag && actual_name == an && desired_name == dn }
      @features.push(feature)
      actual_name
    end

    # This runs when the DFStock *module* is *included* into a DFHack::StockpileSettings *class* - it creates the accessors
    #
    # Note: Unlike most modules, the accessors aren't defined on the module, this act of inclusion
    # triggers the manual creation of the accessors.
    def included klass
      # p [:included, :self, self, :into, klass, :features, @features.length, @features]

      flags = []
      arrays = []
      @features.each {|type, actual_name, desired_name, stockklass|
        desired_name ||= actual_name
        if :flag == type
          base_name = "flag_#{actual_name}".to_sym
          flags << [actual_name, desired_name, base_name]
          # p [:define_flag, :self, self, :klass, klass, :an, actual_name, :bn, base_name, :dn, desired_name]
          if !klass.method_defined? base_name
            # reader
            klass.class_eval "alias    #{base_name}  #{actual_name}",  __FILE__, __LINE__
            klass.class_eval "alias #{desired_name}    #{base_name}",  __FILE__, __LINE__
            # writer
            klass.class_eval "alias    #{base_name}= #{actual_name}=", __FILE__, __LINE__
            klass.class_eval "alias #{desired_name}=   #{base_name}=", __FILE__, __LINE__
          end

        elsif :array == type
          base_name = "array_#{actual_name}".to_sym
          arrays << [actual_name, desired_name, base_name]
          # p [:define_array, :self, self, :klass, klass, :an, actual_name, :bn, base_name, :dn, desired_name]
          if !klass.method_defined? base_name
            raise "Ack! Trying to add #{actual_name} to #{stockklass}" unless klass.instance_methods.include?(actual_name)
            klass.class_eval "alias #{base_name} #{actual_name}", __FILE__, __LINE__
          end
          # p [:defining_method, desired_name, :on_class, klass, :from, stockklass, :base_name, base_name]
          klass.send(:define_method, desired_name) {|&b|
            # Cache the item array - it must be linked to the flags array so each stock-settings instance must have its own
            # @@instances ||= {} # On the Scaffold module
            # @@instances[[desired_name, _memaddr]] ||=
            begin
              array = stockklass.num_instances.times.map {|idx|
                stockklass.new idx, category: self, subcategory_name: desired_name
              }

              # p [:in, desired_name, :as_instance, self, :from, stockklass, :base_name, base_name, :array_length, array.length, :flags_length, flags_array.length]
              # puts "WARNING: #{stockklass} - the flags array #{base_name} is larger than the #{desired_name} array. #{flags_array.length} > #{array.length}" if flags_array.length > array.length # DEBUG

              def array.[]= i, v ; self[i].set !!v end # Treat the array like one of booleans on assignment
              array
            end
          }

        else ; raise "Unknown type #{type}" end
      }

      klass.send(:define_method, :flags) {
        desired_names = flags.map  {|_, desired_name, _| desired_name }
        pairs = desired_names.map {|desired_name| [desired_name, send(desired_name)] }.inject(&:+)
        Hash[*pairs]
      }
      klass.send(:define_method, :arrays) {
        desired_names = arrays.map {|_, desired_name, _| desired_name }
        pairs = desired_names.map {|desired_name| [desired_name, send(desired_name)] }.inject(&:+)
        Hash[*pairs]
      }

      features = @features.dup
      klass.send(:define_method, :features) { features }

      # Some subcategories have been renamed for consitency, stone.mats to stone.ore, etc. A wrapper is then constructed
      # at the original name (:mats) to provide existing array-of-booleans functionality for existing scripts.
      #
      # A shared wrapper is for a subcategory which has been broken into multiple new categories.
      wrappers = arrays + flags
      wrapper_count = Hash.new {|h,k| h[k] = 0 }
      wrappers.each {|an,dn,bn| wrapper_count[an] += 1 }
      simple_wrappers, shared_wrappers = wrappers.partition {|an, dn, bn| wrapper_count[an] == 1 }

      simple_wrappers.each {|actual_name, desired_name, _|
        next if actual_name == desired_name
        # p [:simple_wrapper, :an, actual_name, :dn, desired_name]
        klass.class_eval { undef_method actual_name }
        klass.class_eval "alias #{actual_name} #{desired_name}", __FILE__, __LINE__
      }
      shared_wrappers.map {|actual_name, _, _| actual_name}.uniq.each {|actual_name|
        wrapped_methods = wrappers.select {|a,d,_| a == actual_name }.map {|a,d,_| d }
        # p [:shared_wrapper, :an, actual_name, :wm, wrapped_methods]
        klass.class_eval { undef_method actual_name }
        klass.class_eval "def #{actual_name} ; #{wrapped_methods.join(' + ')} end", __FILE__, __LINE__
      }

      klass.class_eval(<<~TXT,__FILE__,__LINE__ + 1)
        # Print a list of the array names, they're easy to forget
        def describe_category
          flags, arrays = features.map {|t,n1,n2,_| [t, (n2 || n1)] }.partition {|t,_| t == :flag }
          puts stock_category_name.to_s + " contains these features:"
          puts "Flags: #{ flags.map  {|_,n| n }.join(', ')}" unless flags.empty?
          puts "Arrays: #{arrays.map {|_,n| n }.join(', ')}" unless arrays.empty?
        end

        # Catch invalid commands and hint at the correct usage
        def method_missing mn, *a ; describe_category ; super ; end
      TXT
    end
  end

end
