module DFStock

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
    def organic cat_name, index ; organic_types(cat_name)[index] end
  end

  module OrganicScaffold
    # Scaffold a linkage to an organic_mat_category and via inheritance, a type hierarchy. Thing -> Plant -> Leaf, etc.
    def organic_category cat
      parentclassname = format_classname parentclass
      selfclassname   = format_classname

      metaclass = (class << self ; self ; end)

      # Class methods
      metaclass.define_method("#{selfclassname}_category") { cat }
      metaclass.define_method("#{selfclassname}_types") { organic_types(send "#{selfclassname}_category") }
      metaclass.define_method("#{selfclassname}_infos") { send("#{selfclassname}_types").map {|t,i| material_info(t,i) } }
      metaclass.define_method("#{selfclassname}_raws")  { send("#{selfclassname}_infos").map &:plant }

      metaclass.define_method("#{selfclassname}_instances") { send("#{selfclassname}_raws").each_with_index.map {|_,i| new i } }
      metaclass.define_method("instances") { send("#{selfclassname}_instances") }

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
  end

  module InorganicCategory
    def inorganic_types ; df.world.raws.inorganics end
  end

  module InorganicScaffold
    def inorganic_subset &discriminator
      parentclassname = format_classname parentclass
      selfclassname   = format_classname
      metaclass = (class << self ; self ; end)

      p [:inorganic_subset, :self, self, :name, selfclassname, :parentname, parentclassname, :meta, metaclass]

      p [:meta_define_method, :_raws]
      # metaclass.define_method("#{selfclassname}_raws") {
      #   p [selfclassname, :_raws, :parent, parentclassname, "#{parentclassname}_instance", caller.length]
      #   # cache([:raws, selfclassname]) {
      #     send("#{parentclassname}_instances").select {|i|
      #       discriminator[i]
      #     }.map(&:raw)
      #   # }
      # }

      metaclass.define_method("#{selfclassname}_discriminator") { discriminator }
      metaclass.class_eval(<<~S_RAWS, __FILE__, __LINE__)
        def #{selfclassname}_raws
          #{parentclassname}_instances.select {|i| #{selfclassname}_discriminator[i] }.map(&:raw)
        end
      S_RAWS

      p [:meta_define_method, :_instances]
      # metaclass.define_method("#{selfclassname}_instances") {
      #   p [selfclassname, :_instances, :parent, parentclassname, caller.length]
      #   send("#{selfclassname}_raws").each_with_index.map {|_,i| new i }
      # }
      metaclass.class_eval(<<~S_INST, __FILE__, __LINE__)
        def #{selfclassname}_instances
          #{selfclassname}_raws.length.times.map {|i| new i }
        end
      S_INST

      # metaclass.define_method("instances") { p [:instances, :self, selfclassname] ; send("#{selfclassname}_instances") }
      metaclass.class_eval(<<~INST, __FILE__, __LINE__)
        def instances ; #{selfclassname}_instances end
      INST

      # metaclass.define_method("index_translation") { (0...send("#{selfclassname}_infos").length).to_a } # FIXME Can this be replaced with an int?
      metaclass.class_eval(<<~IDX_T, __FILE__, __LINE__)
        def index_translation ; (0...#{selfclassname}_raws.length).to_a end
      IDX_T

      # Create a hook to find an instance's index based on its raw, for child-classes to link through
      # define_method("#{selfclassname}_by_raw") {|raw| self.class.send("#{selfclassname}_raws").index raw }
      class_eval(<<~BY_RAW, __FILE__, __LINE__)
        def #{selfclassname}_by_raw ; #{selfclassname}_raws.index raw end
      BY_RAW

      # Using the Parent.parent_by_raw method, if it exists, to provide the Self.parent_index method
      if parentclass.instance_methods.include?("#{parentclassname}_by_raw".to_sym)
        # define_method("#{parentclassname}_index") {
        #   send "#{parentclassname}_by_raw", raw
        # }
        class_eval(<<~P_IDX, __FILE__, __LINE__)
          def #{parentclassname}_index ; #{parentclassname}_by_raw raw end
        P_IDX
      end
    end
  end
end
