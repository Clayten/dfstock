module DFStock

  module Categories
    def materials_builtin ; df.world.raws.mat_table.builtin.to_a.compact end

    def raws_plant        ; df.world.raws.plants.all end

    def raws_creature     ; df.world.raws.creatures.all end

    def raws_inorganic    ; df.world.raws.inorganics end

    def raws_item         ; df.world.raws.itemdefs.all end

    # organic categories
    def mat_table ; df.world.raws.mat_table end
    def organic_types cat_name
      cat_num = DFHack::OrganicMatCategory::NUME[cat_name]
      raise "Unknown category '#{cat_name.inspect}'" unless cat_num
      cache(:organics) {
        mat_table.organic_types.each_with_index.map {|ot,i| ot.zip mat_table.organic_indexes[i] }
      }[cat_num]
    end
  end

  module StockScaffold
    def from_builtins &discriminator
      # p [:from_builtins, :self, self]

      metaclass.define_method("discriminator") { discriminator }

      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.materials ; cache([:materials, self]) { materials_builtin.select {|m| i = new(material: m) ; discriminator[i] } } end
        def self.materials_index ; cache([:mat_index, self]) { Hash[*materials.each_with_index.map {|m,i| [m._memaddr, i] }.reverse.flatten] } end

        def raw ; nil end
        def material
          # p [:mat, self.class, !!@material, index, instance_variables]
          return @material if @material
          raise "No index for #{self}" unless index
          self.class.materials[index] end
      TXT
    end

    def from_raws type, &discriminator
      # p [:from_raws, :self, self]

      metaclass.define_method("discriminator") { discriminator }

      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.raws ; cache([:raws, self]) { raws_#{type}.select {|r| $r = r ; i = new(raw: r) ; discriminator[i] } } end
        def self.raws_index ; cache([:raw_index, self]) { Hash[*raws.each_with_index.map {|r,i| [r._memaddr, i] }.reverse.flatten] } end
      TXT
    end

    def from_category cat
      # p [:from_category, :self, self, :cat, cat]

      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.category  ; :#{cat} end
        def self.types     ; cache([:types,     self]) { organic_types(category) } end
        def self.infos     ; cache([:infos,     self]) { types.map {|t,i| material_info t, i } } end
        def self.raws      ; cache([:raws,      self]) { infos.map {|i| i.send(i.mode.downcase) } } end
        def self.materials ; cache([:materials, self]) { infos.map &:material } end
        def self.raws_index ; cache([:raw_index, self]) { Hash[*raws.each_with_index.map {|r,i| [r._memaddr, i] }.reverse.flatten] } end

        def material  ; @material || (@raw.material.first if @raw) || self.class.materials[index] end

        # The categories generally list a specific material and the other materials are a distraction
        def materials ; [material] end

        def token ; self.class.infos[index].token end
      TXT
    end

    def from_list list
      # p [:from_list, :self, self, :list_length, list.length]

      metaclass.define_method(:types) { list }

      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.types_index ; cache([:type_index, self]) { Hash[*types.each_with_index.map {|t,i| [t, i] }.flatten] } end

        def type ; @type || self.class.types[index] end
        def name ; type end
      TXT
    end
  end
end
