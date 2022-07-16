require 'thing/thing'

module DFStock

  class Ammo2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefAmmost }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class Weapon2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefWeaponst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class TrapWeapon2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefTrapcompst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorBody2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefArmorst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorHead2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefHelmst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorFeet2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefShoesst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorHand2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefGlovesst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorLeg2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefPantsst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end

  class ArmorShield2 < Thing2
    from_raws(:item) {|x| x.raw.class == DFHack::ItemdefShieldst }
    def token ; title_case "#{"#{raw.adjective} " if raw.adjective}#{raw.name_plural}".strip end
  end
end
