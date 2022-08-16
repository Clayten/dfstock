$LOAD_PATH << File.dirname(__FILE__)
require 'thing/thing'
require 'scaffold'
require 'stockpile/settings'
require 'stockpile/buildings'
require 'linkages'

module DFStock
  def self.clear_error_before_loading
    return if $!.nil?
    puts "Clearing lingering error message"
    begin
      load '~/foo'
    rescue LoadError => e
      puts "Rescuing"
    end
  end
  def self.loadfile fn
    # puts "Loading #{fn}"
    load fn
  end
  def self.libs
    Dir.glob("#{File.dirname __FILE__}/**/*rb")
  end
  def self.reload
    return :already_reloading if caller.any? {|c| c =~ /:in `reload'/ }
    clear_error_before_loading
    libs.each {|f| loadfile f }
    puts "Finished reload"
  end
end
DFStock.reload

module DFStock
  def self.pathname_separator ; '|' end

  def self.buildings ; df.world.buildings.all.select {|x| x.class <= DFHack::Building } end
  def self.stockpiles
    buildings.select {|x| x.class == DFHack::BuildingStockpilest }
  end
  def self.linkable_workshops
    buildings.select {|x| x.class == DFHack::BuildingWorkshopst && x.respond_to?(:getStockpileLinks) && x.getStockpileLinks }
  end
  def self.hauling_stops # HaulingStops - there often are multiple at the same location for manually-guided routes.
    df.ui.hauling.routes.map {|r| r.stops.to_a }.flatten
  end
end

# debug methods
def wrap ; r = nil ; begin ; r = yield ; rescue Exception => e ; $e = e ; end ; r || e end
def try &b ; r = wrap &b ; puts(r.backtrace[0..12],'...',r.backtrace[-12..-1]) if r.is_a?(Exception) ; r end
def time ; s = Time.now ; r = yield ; puts "Took #{Time.now - s}s" ; r end

# UX Convenience methods at top level
def pile_at_cursor
  c = df.cursor
  (DFStock.stockpiles + DFStock.hauling_stops + DFStock.linkable_workshops).find {|b|
    if b.respond_to? :pos # Hauling Stops - Warning: Will only find the first stop at a location
      b.pos.z == c.z &&
        b.pos.x == c.x &&
        b.pos.y == c.y
    elsif b.respond_to?(:room) && b.room.extents
      next unless c.z == b.z
      ox = c.x - b.room.x
      oy = c.y - b.room.y
      next if ox < 0 || ox > b.room.width || oy < 0 || oy > b.room.height
      offset = ox + oy * b.room.width
      b.room.extents[offset] == :Stockpile
    else
      b.z == c.z &&
        b.x1 <= c.x && b.x2 >= c.x &&
        b.y1 <= c.y && b.y2 >= c.y
    end
  }
end
