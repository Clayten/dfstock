require 'thing/builtin'
require 'thing/inorganic'
require 'thing/creature'
require 'thing/plant'

module DFStock
  class Thing
    include   BuiltinQueries
    include InorganicQueries
    include  CreatureQueries
    include     PlantQueries
  end
end
