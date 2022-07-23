require 'thing/thing'

module DFStock
  class Builtin < Thing
    from_builtins { true }
    def name ; material.state_name[:Solid] end
  end

  class Glass < Thing
    from_builtins {|x| x.is_glass? }
    def name ; material.state_name[:Solid] end
  end
end
