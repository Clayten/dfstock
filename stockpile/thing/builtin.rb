require 'thing/thing'

module DFStock
  class Builtin < Thing
    from_builtins { true }
    def token ; material.state_name[:Solid] end
  end

  class Glass < Thing
    from_builtins {|x| x.is_glass? }
    def token ; material.state_name[:Solid] end
  end
end
