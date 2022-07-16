require 'thing/thing'

module DFStock
  class Furniture2 < Thing2
  end

  class MiscLiquid2 < Thing2
    def self.materials ; [materials_builtin[11], raws_inorganic[33].material] end

    def raw ; false ; end
    def token ; material.state_name[:Liquid] end
  end

end
