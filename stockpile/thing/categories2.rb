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
      pcn = format_classname parentclass
      scn = format_classname
      mc = (class << self ; self ; end)

      mc.class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def #{scn}_category ; #{cat.inspect} end
        def #{scn}_types ; cache([:types, :#{scn}]) { organic_types(#{scn}_category) } end
        def #{scn}_infos ; cache([:infos, :#{scn}]) { #{scn}_types.map {|t,i| material_info(t,i) } } end
        def #{scn}_raws  ; cache([:raws,  :#{scn}]) { #{scn}_infos.map &:plant } end

        def #{scn}_instances ; #{scn}_raws.each_index {|i| new i } end
        alias instances #{scn}_instances

        def index_translation ; (0...#{scn}_infos.length).to_a end

        # Create a hook to find an instance's index based on its raw, for child-classes to link through
        def #{scn}_by_raw raw ; #{scn}_raws.index raw end
      TXT

      # Using the Parent.parent_by_raw method, if it exists, to provide the Self.parent_index method
      class_eval(<<~TXT, __FILE__, __LINE__ + 1) if parentclass.instance_methods.include?("#{pcn}_by_raw".to_sym)
        def #{pcn}_index ; self.class.#{pcn}_by_raw raw end
      TXT
    end
  end

  module InorganicCategory
    def inorganic_types ; df.world.raws.inorganics end
  end

  module InorganicScaffold
    def inorganic_subset &discriminator
      pcn = format_classname parentclass
      scn = format_classname
      mc = (class << self ; self ; end)

      # p :_
      # p [:inorganic_subset, :self, self, :name, scn, :parentname, pcn, :meta, mc]

      # Save the discriminator block as a closure
      mc.define_method("#{scn}_discriminator") { discriminator }

      mc.class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def #{scn}_indexes   ; cache([:indexes,   :#{scn}]) { #{pcn}_instances.each_with_index.select {|x,i| #{scn}_discriminator[x] }.map(&:last) } end
        def #{scn}_raws      ; cache([:raws,      :#{scn}]) { #{scn}_indexes.map {|i| #{pcn}_instances[i].raw } } end

        def #{scn}_instances ; cache([:instances, :#{scn}]) { #{scn}_raws.length.times.map {|i| #{self.to_s}.new i } } end
        alias instances #{scn}_instances

        # FIXME - replace with something that returns just .self_raws.length
        def index_translation ; (0...#{scn}_raws.length).to_a end

        # Create a hook to find an index based on a raw, for child-classes to link through
        def #{scn}_by_raw raw ; #{scn}_raws.index raw end
      TXT

      # Using the Parent.parent_by_raw method, if it exists, to provide the parent_index method
      class_eval(<<~TXT, __FILE__, __LINE__ + 1) if parentclass.methods.include?("#{pcn}_by_raw".to_sym)
        # p [:creating_parent_index_instance_method, scn, pcn]
        def #{pcn}_index ; self.class.#{pcn}_by_raw raw end
      TXT
    end
  end
end
