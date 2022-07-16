module DFStock

  module ItemCategory
    def raws_item ; df.world.raws.itemdefs.all end
  end

  module BuiltinCategory
    def materials_builtin ; df.world.raws.mat_table.builtin.to_a.compact end
  end

  module OrganicCategory
    def raws_plant ; df.world.raws.plants.all end

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

  module InorganicCategory
    def inorganic_types ; df.world.raws.inorganics end
    alias raws_inorganic inorganic_types
  end

  module CreatureCategory
    def raws_creature ; df.world.raws.creatures.all end
  end

  module GenericScaffold
    def from_builtins &discriminator
      pcn = format_classname parentclass
      scn = format_classname
      mc = (class << self ; self ; end)

      # p [:from_builtins, :self, self, :name, scn, :parentname, pcn, :meta, mc]

      # Save the discriminator block as a closure
      mc.define_method("discriminator") { discriminator }
      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.materials ; cache([:materials, :#{scn}]) { materials_builtin.select {|m| i = new(material: m) ; discriminator[i] } } end

        def raw ; nil end
        def material ; @material || self.class.materials[index] end
      TXT
    end

    def from_raws type, &discriminator
      pcn = format_classname parentclass
      scn = format_classname
      mc = (class << self ; self ; end)

      # p [:from_raws, :self, self, :name, scn, :parentname, pcn, :meta, mc]

      # Save the discriminator block as a closure
      mc.define_method("discriminator") { discriminator }
      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.raws ; cache([:raws, :#{scn}]) { raws_#{type}.select {|r| $r = r ; i = new(raw: r) ; discriminator[i] } } end
      TXT
    end

    def from_category cat
      pcn = format_classname parentclass
      scn = format_classname

      # p [:from_category, :self, self, :cat, cat, :name, scn, :parentname, pcn]

      class_eval(<<~TXT, __FILE__, __LINE__ + 1)
        def self.category  ; :#{cat} end
        def self.types     ; cache([:types,     :#{scn}]) { organic_types(category) } end
        def self.infos     ; cache([:infos,     :#{scn}]) { types.map {|t,i| material_info t, i } } end
        def self.raws      ; cache([:raws,      :#{scn}]) { infos.map {|i| i.send(i.mode.downcase) } } end
        def self.materials ; cache([:materials, :#{scn}]) { infos.map &:material } end
      TXT
    end
  end
end
