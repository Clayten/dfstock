require 'thing/thing'

module DFStock

  class Ammo < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefAmmost }
    def material ; nil end
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class Weapon < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefWeaponst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class TrapWeapon < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefTrapcompst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorBody < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefArmorst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorHead < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefHelmst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorFeet < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefShoesst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorHand < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefGlovesst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorLeg < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefPantsst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end

  class ArmorShield < Thing
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefShieldst }
    def token ; title_case "#{"#{adjective} " if adjective}#{raw_name_plural}".strip end
  end
end
