class DFHack::BuildingStockpilest
  alias settings_ settings unless instance_methods.include? :settings_
  def settings ; @@settings ||= {} ; @@settings[_memaddr] ||= settings_ end
end
class DFHack::HaulingStop
  alias settings_ settings unless instance_methods.include? :settings_
  def settings ; @@settings ||= {} ; @@settings[_memaddr] ||= settings_ end
end

module DFHack::StockForwarder
  def self.included *x ; super end
  # Wrappers to allow the stockpile to be used as the settings object itself.
  def allow_organic       ; settings.allow_organic end
  def allow_organic=   b  ; settings.allow_organic= b end
  def allow_inorganic     ; settings.allow_inorganic end
  def allow_inorganic= b  ; settings.allow_inorganic= b end
  def stock_flags         ; settings.flags end # renamed to avoid conflict

  def animals             ; settings.animals end
  def food                ; settings.food end
  def furniture           ; settings.furniture end
  def corpses             ; settings.corpses end
  def refuse              ; settings.refuse end
  def stone               ; settings.stone end
  def ammo                ; settings.ammo end
  def coins               ; settings.coins end
  def bars_blocks         ; settings.bars_blocks end
  def gems                ; settings.gems end
  def finished_goods      ; settings.finished_goods end
  def leather             ; settings.leather end
  def cloth               ; settings.cloth end
  def wood                ; settings.wood end
  def weapons             ; settings.weapons end
  def armor               ; settings.armor end
  def sheet               ; settings.sheet end

  def find_by_pathname *a ; settings.find_by_pathname *a end
  def categories          ; settings.categories end
  def all_items           ; settings.all_items end
  def enabled_items       ; settings.enabled_items end
  def pathnames           ; settings.pathnames end
  def enabled_pathnames   ; settings.enabled_pathnames end
  def length              ; settings.length end
  def copy o              ; settings.copy o end
  def == o                ; settings == o end
  def - o                 ; settings - o end
  def + o                 ; settings + o end
  def & o                 ; settings & o end
  def ^ o                 ; settings ^ o end
end

class DFHack::BuildingStockpilest
  include DFHack::StockForwarder

  def status
    puts "Stockpile ##{stockpile_number} - #{name.inspect}"
    puts "# Max Barrels: #{max_barrels} - # Max Bins: #{max_bins} - # Max Wheelbarrows: #{max_wheelbarrows}"
    bins, barrels = [:BIN, :BARREL].map {|t| container_type.select {|i| i == t }.length }
    puts "# of Containers: #{container_type.length}, bins: #{bins}, barrels: #{barrels}"
    puts "Mode: #{use_links_only == 1 ? 'Use Links Only' : 'Take From Anywhere'}"

    puts "Linked Stops: #{linked_stops.length} #{linked_stops.map(&:name).join}"
    puts "Incoming Stockpile Links: #{links.take_from_pile.length} - #{
      links.take_from_pile.map(&:name).join(', ')}"
    puts "Outgoing Stockpile Links: #{links.give_to_pile.length} - #{
      links.give_to_pile.map(&:name).join(', ')}"
    puts "Incoming Workshop Links: #{links.take_from_workshop.length} - #{
      links.take_from_workshop.map {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"
    puts "Outgoing Workshop Links: #{links.give_to_workshop.length} - #{
      links.give_to_workshop.map   {|w| [w.type,w.name].reject(&:empty?).join(':') }.join(', ')}"

    settings.status

    true
  end

  def get_links
    links = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }
    links[:stockpile][:give] = self.links.give_to_pile.to_a unless self.links.give_to_pile.empty?
    links[:stockpile][:take] = self.links.take_from_pile.to_a unless self.links.take_from_pile.empty?
    links[:workshop ][:give] = self.links.give_to_workshop.to_a unless self.links.give_to_workshop.empty?
    links[:workshop ][:take] = self.links.take_from_workshop.to_a unless self.links.take_from_workshop.empty?
    # lookup all hauling stops to see which ones point here
    give_stops, take_stops = DFStock::hauling_stops.
      map {|h| h.stockpiles.map {|s| [h,s] } }.
      inject(&:+).
      select {|h, s| s.building_id == id }.
      partition {|h, s| !s.mode.give }.
      map {|a| a.map &:first }
    links[:hauling  ][:give] = give_stops unless give_stops.empty?
    links[:hauling  ][:take] = take_stops unless take_stops.empty?
    links
  end
end

class DFHack::HaulingStop
  include DFHack::StockForwarder

  def status
    puts "Trackstop ##{id} - #{name.inspect}"

    links = get_links[:stockpile]
    give, take = links[:give], links[:take]
    puts "Incoming Stockpile Links: #{take.length} - #{ take.map(&:name).join(', ')}"
    puts "Outgoing Stockpile Links: #{give.length} - #{ give.map(&:name).join(', ')}"
    puts "StockSelection:"
    settings.status
    true
  end

  def get_links
    links = Hash.new {|h,k| h[k] = [] }
    stockpiles.each {|link|
      mode = link.mode.give ? :give : :take
      building = df.world.buildings.all.find {|b| b.id == link.building_id }
      links[mode] << building
    }
    {:stockpile => links}
  end
end

class DFHack::BuildingWorkshopst
  def get_links
    links = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }
    links[:stockpile][:give] = getStockpileLinks.give_to_pile.to_a unless getStockpileLinks.give_to_pile.empty?
    links[:stockpile][:take] = getStockpileLinks.take_from_pile.to_a unless getStockpileLinks.take_from_pile.empty?
    links
  end
end
