module DFStock

  class Builtin < Thing
    def self.builtin_materials ; df.world.raws.mat_table.builtin.to_a end
    def self.builtin_indexes ; builtin_materials.each_with_index.reject {|x,i| !x }.map {|v,i| i } end
    def self.builtins ; builtin_indexes.each_index.map {|i| Builtin.new i } end
    # def self.index_translation ; builtin_indexes end

    def index ; self.class.builtin_indexes[builtin_index] end
    def material ; self.class.builtin_materials[index] end
    def materials ; [material] end

    def is_glass? ; material.flags[:IS_GLASS] end

    def to_s ; super + " builtin_index=#{builtin_index}" end
    def token ; material.state_name[:Solid] end

    attr_reader :builtin_index
    def initialize index, link: nil
      @builtin_index = index
      super
    end
  end

  class Glass < Builtin
    def self.glass_indexes ; cache(:glasses) { builtins.each_with_index.inject([]) {|a,(m,i)| a << i if m.is_glass? ; a } } end
    def self.glasses ; glass_indexes.each_index.map {|i| Glass.new i } end
    # def self.index_translation ; glass_indexes end

    def builtin_index ; self.class.glass_indexes[glass_index] end
    def to_s ; super + " glass_index=#{glass_index}" end

    attr_reader :glass_index
    def initialize index, link: nil
      @glass_index = index
      super builtin_index, link: link
    end
  end

end

