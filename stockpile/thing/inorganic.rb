module DFStock

  module InorganicQueries
    def is_magma_safe?
      # p [:ims?, self, :material, material]
      return nil unless material && material.heat

      magma_temp = 12000
      mft = material.heat.mat_fixed_temp
      return true  if mft && mft != 60001

      cdp = material.heat.colddam_point
      return false if cdp && cdp != 60001 && cdp < magma_temp

      %w(heatdam ignite melting boiling).all? {|n|
        t = material.heat.send("#{n}_point")
        t == 60001 || t > magma_temp
      }
    end
  end

  # raw -> material
  class Inorganic < Thing
    def self.inorganic_raws ; df.world.raws.inorganics end
    def self.inorganic_indexes ; (0 ... inorganic_raws.length).to_a end
    def self.inorganics ; inorganic_indexes.each_index.map {|i| Inorganic.new i } end
    # def self.index_translation ; inorganic_indexes end

    def raw ; self.class.inorganic_raws[index] end
    def materials ; [raw.material] end

    def token ; material.state_name[:Solid] end

    def is_gem? ; material.flags[:IS_GEM] end
    def is_stone? ; material.flags[:IS_STONE] end
    def is_metal? ; material.flags[:IS_METAL] end

    def is_soil? ; raw.flags[:SOIL] end
    def is_ore? ; raw.flags[:METAL_ORE] end

    def is_economic_stone?
      !is_ore? &&
      !is_metal? &&
      !is_soil? &&
      !raw.economic_uses.empty?
    end

    def is_clay?
       raw.id =~ /CLAY/ &&
      !raw.flags[:AQUIFER] &&
      !is_stone?
    end

    def is_other_stone?
       is_stone? &&
      !is_ore? &&
      !is_economic_stone? &&
      !is_clay? &&
      !material.flags[:NO_STONE_STOCKPILE]
    end

    def initialize index, link: nil
      super
    end
  end

  class Metal < Inorganic
    def self.metal_indexes ; cache(:metals) { inorganics.each_with_index.inject([]) {|a,(m,i)| a << i if m.is_metal? ; a } } end
    def self.metals ; metal_indexes.each_index.map {|i| Metal.new i } end
    # def self.index_translation ; metal_indexes end

    def inorganic_index ; self.class.metal_indexes[metal_index] end
    def to_s ; super + " metal_index=#{metal_index}" end

    attr_reader :metal_index
    def initialize index, link: nil
      @metal_index = index
      super inorganic_index, link: link
    end
  end

  class Gem < Inorganic # Fixme - Why stone_index not inorganic_index?
    def self.gem_indexes ; cache(:gems) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_gem? ; a } } end
    def self.gems ; gem_indexes.each_index.map {|i| Gem.new i } end
    # def self.index_translation ; gem_indexes end

    def stone_index ; self.class.gem_indexes[gem_index] end
    def to_s ; super + " gem_index=#{gem_index}" end

    attr_reader :gem_index
    def initialize index, link: nil
      @gem_index = index
      super stone_index, link: link
    end
  end

  class CutStone < Inorganic # NOTE: A Different definition of stone than the stone stockpile
    # FIXME - Should be inorganic_index, not stone_index
    def self.cutstone_indexes ; cache(:cutstones) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_stone? ; a } } end
    def self.cutstones ; cutstone_indexes.each_index.map {|i| CutStone.new i } end
    # def self.index_translation ; cutstone_indexes end

    def stone_index ; self.class.cutstone_indexes[cutstone_index] end
    def to_s ; super + " cutstone_index=#{cutstone_index}" end

    attr_reader :cutstone_index
    def initialize index, link: nil
      @cutstone_index = index
      super stone_index, link: link
    end
  end

  class Stone < Inorganic # NOTE: Not IS_STONE, but members of the stone stockpile
    def self.stone_indexes ; (ore_indexes + economicstone_indexes + otherstone_indexes + clay_indexes).sort end
    def self.stones ; stone_indexes.each_index.map {|i| Stone.new i } end
    # def self.index_translation ; stone_indexes end

    def self.ore_indexes           ; cache(:ores)      { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_ore? ; a } } end
    def self.economicstone_indexes ; cache(:economics) { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_economic_stone? ; a } } end
    def self.otherstone_indexes    ; cache(:others)    { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_other_stone? ; a } } end
    def self.clay_indexes          ; cache(:clays)     { inorganics.each_with_index.inject([]) {|a,(s,i)| a << i if s.is_clay? ; a } } end

    def inorganic_index ; self.class.stone_indexes[stone_index] end
    def to_s ; super + " stone_index=#{stone_index}" end

    attr_reader :stone_index
    def initialize index, link: nil
      @stone_index = index
      super inorganic_index, link: link
    end
  end

  class Ore < Stone # FIXME: Make dependant on Stone indexes, not directly on Inorganic
    def self.ores ; ore_indexes.each_index.map {|i| Ore.new i } end
    # def self.index_translation ; ore_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.ore_indexes[ore_index] end
    def to_s ; super + " ore_index=#{ore_index}" end

    attr_reader :ore_index
    def initialize index, link: nil
      @ore_index = index
      super stone_index, link: link
    end
  end

  class EconomicStone < Stone
    def self.economicstones ; economicstone_indexes.each_index.map {|i| new i } end
    # def self.index_translation ; economicstone_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.economicstone_indexes[economic_index] end
    def to_s ; super + " economic_index=#{economic_index}" end

    attr_reader :economic_index
    def initialize index, link: nil
      @economic_index = index
      super stone_index, link: link
    end
  end

  class OtherStone < Stone
    def self.otherstones ; otherstone_indexes.each_index.map {|i| OtherStone.new i } end
    # def self.index_translation ; otherstone_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.otherstone_indexes[other_index] end
    def to_s ; super + " other_index=#{other_index}" end

    attr_reader :other_index
    def initialize index, link: nil
      @other_index = index
      super stone_index, link: link
    end
  end

  class Clay < Stone
    def self.clays ; clay_indexes.each_index.map {|i| Clay.new i } end
    # def self.index_translation ; clay_indexes end

    def stone_index ; self.class.stone_indexes.index self.class.clay_indexes[clay_index] end
    def to_s ; super + " clay_index=#{clay_index}" end

    attr_reader :clay_index
    def initialize index, link: nil
      @clay_index = index
      super stone_index, link: link
    end
  end

end
