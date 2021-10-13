module DFStock

  # Things that aren't just a material - like chairs
  class Item < Thing
    def self.item_raws ; df.world.raws.itemdefs.all end
    def self.item_indexes ; (0 ... item_raws.length).to_a end
    def self.items ; item_indexes.map {|i| Item.new i } end
    # def self.index_translation ; item_indexes end

    def raw ; self.class.item_raws[item_index] end

    def material ; end
    def materials ; [] end

    def adjective ; raw.adjective if raw.respond_to?(:adjective) && !raw.adjective.empty? end
    def name ; raw.name end
    def name_plural ; raw.respond_to?(:name_plural) ? raw.name_plural   : raw.name end
    def flags       ; raw.respond_to?(:flags)       ? raw.flags.a       : [] end
    def base_flags  ; raw.respond_to?(:base_flags)  ? raw.base_flags.a  : [] end
    def props_flags ; raw.respond_to?(:props)       ? raw.props.flags.a : [] end
    def raw_strings ; raw.respond_to?(:raw_strings) ? raw.raw_strings   : [] end

    def to_s ; super + " item_index=#{item_index}" end
    def token ; "#{"#{adjective} " if adjective}#{name_plural}" end

    attr_reader :item_index
    def initialize index, link: nil
      @item_index = index
      super
    end
  end

  class Ammo < Item
    def self.ammo_indexes ; item_raws.each_with_index.select {|i,_| i.class == DFHack::ItemdefAmmost }.map {|_,i| i } end
    def self.ammos ; ammo_indexes.each_index.map {|i| Ammo.new i } end
    # def self.index_translation ; ammo_indexes end

    def item_index ; self.class.ammo_indexes[ammo_index] end

    def natural_state ; {0 => :Liquid, 1 => :Solid}[ammo_index] end
    def token ; [raw.adjective, raw.name_plural].reject(&:empty?).map(&:capitalize).join(' ') end
    def to_s ; super + " ammo_index=#{ammo_index}" end

    attr_reader :ammo_index
    def initialize index, link: nil
      @ammo_index = index
      super
    end
  end

  # Bool array is large enough for weapons, not all items.
  class Weapon < Item
    def self.weapon_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefWeaponst }.map {|x,i| i } end
    def self.weapons ; weapon_indexes.each_index.map {|i| Weapon.new i } end
    # def self.index_translation ; weapon_indexes end

    def item_index ; self.class.weapon_indexes[weapon_index] end

    def token ; title_case super end
    def to_s ; super + " weapon_index=#{weapon_index}" end

    attr_reader :weapon_index
    def initialize index, link: nil
      @weapon_index = index
      super
    end
  end

  class TrapWeapon < Item
    def self.trapweapon_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefTrapcompst }.map {|x,i| i } end
    def self.trapweapons ; trapweapon_indexes.each_index.map {|i| TrapWeapon.new i } end
    # def self.index_translation ; trapweapon_indexes end

    def item_index ; self.class.trapweapon_indexes[trapweapon_index] end

    def token ; title_case super end
    def to_s ; super + " trapweapon_index=#{trapweapon_index}" end

    attr_reader :trapweapon_index
    def initialize index, link: nil
      @trapweapon_index = index
      super
    end
  end

  class ArmorBody < Item
    def self.armorbody_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefArmorst }.map {|x,i| i } end
    def self.armorbodys ; armorbody_indexes.each_index.map {|i| ArmorBody.new i } end
    # def self.index_translation ; armorbody_indexes end

    def item_index ; self.class.armorbody_indexes[armorbody_index] end

    def token ; title_case super end
    def to_s ; super + " armorbody_index=#{armorbody_index}" end

    attr_reader :armorbody_index
    def initialize index, link: nil
      @armorbody_index = index
      super
    end
  end

  class ArmorHead < Item
    def self.armorhead_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefHelmst }.map {|x,i| i } end
    def self.armorheads ; armorhead_indexes.each_index.map {|i| ArmorHead.new i } end
    # def self.index_translation ; armorhead_indexes end

    def item_index ; self.class.armorhead_indexes[armorhead_index] end

    def token ; title_case super end
    def to_s ; super + " armorhead_index=#{armorhead_index}" end

    attr_reader :armorhead_index
    def initialize index, link: nil
      @armorhead_index = index
      super
    end
  end

  class ArmorFeet < Item
    def self.armorfeet_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefShoesst }.map {|x,i| i } end
    def self.armorfeets ; armorfeet_indexes.each_index.map {|i| ArmorFeet.new i } end
    # def self.index_translation ; armorfeet_indexes end

    def item_index ; self.class.armorfeet_indexes[armorfeet_index] end

    def token ; title_case super end
    def to_s ; super + " armorfeet_index=#{armorfeet_index}" end

    attr_reader :armorfeet_index
    def initialize index, link: nil
      @armorfeet_index = index
      super
    end
  end

  class ArmorHand < Item
    def self.armorhand_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefGlovesst }.map {|x,i| i } end
    def self.armorhands ; armorhand_indexes.each_index.map {|i| ArmorHand.new i } end
    # def self.index_translation ; armorhand_indexes end

    def item_index ; self.class.armorhand_indexes[armorhand_index] end

    def token ; title_case super end
    def to_s ; super + " armorhand_index=#{armorhand_index}" end

    attr_reader :armorhand_index
    def initialize index, link: nil
      @armorhand_index = index
      super
    end
  end

  class ArmorLeg < Item
    def self.armorleg_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefPantsst }.map {|x,i| i } end
    def self.armorlegs ; armorleg_indexes.each_index.map {|i| ArmorLeg.new i } end
    # def self.index_translation ; armorleg_indexes end

    def item_index ; self.class.armorleg_indexes[armorleg_index] end

    def token ; title_case super end
    def to_s ; super + " armorleg_index=#{armorleg_index}" end

    attr_reader :armorleg_index
    def initialize index, link: nil
      @armorleg_index = index
      super
    end
  end

  class ArmorShield < Item
    def self.armorshield_indexes ; items.each_with_index.select {|x,i| x.raw.class == DFHack::ItemdefShieldst }.map {|x,i| i } end
    def self.armorshields ; armorshield_indexes.each_index.map {|i| ArmorShield.new i } end
    # def self.index_translation ; armorshield_indexes end

    def item_index ; self.class.armorshield_indexes[armorshield_index] end

    def token ; title_case super end
    def to_s ; super + " armorshield_index=#{armorshield_index}" end

    attr_reader :armorshield_index
    def initialize index, link: nil
      @armorshield_index = index
      super
    end
  end

end
