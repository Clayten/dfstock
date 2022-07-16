require 'thing/thing'
require 'thing/thing2'

module DFStock
  class Builtin2 < Thing2
    from_builtins { true }
    def token ; material.state_name[:Solid] end
  end

  class Glass2 < Thing2
    from_builtins {|x| x.is_glass? }
    def token ; material.state_name[:Solid] end
  end
end
