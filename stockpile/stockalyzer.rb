# Analyzes stock flow into and out of shops, piles, and QSPs
module DFStockalyzer
  extend DwarfFortressUtils::API
  class << self
    def buildings ; df.world.buildings.all end

    def find_building_by_id          id ; buildings.find   {|b| b.id    == id    } end
    def select_buildings_by_class klass ; buildings.select {|b| b.class == klass } end

    def building_type_by_id id
      building = find_building_by_id id
      [building.getType, (building.type rescue nil)]
    end

    def stockpiles ; select_buildings_by_class DFHack::BuildingStockpilest end
    def trackstops ; select_buildings_by_class DFHack::BuildingTrapst end

    # Traverse piles and move items that will flow
    def flow_all_items
      raise
    end

    # If a stockpile job is waiting, fulfill it.
    # FIXME - Doesn't work, crashes game. Things needs to be unlinked as well.
    def teleport_all_job_items pile_id = nil
      $Item_Movements = @movements = []
      $Item_IDs = @item_ids = Hash.new {|h,k| h[k] = [] }
      count = 0
      piles = pile_id ? [find_building_by_id(pile_id)] : stockpiles
      piles.each {|sp|
        p [:pile, sp.id]
        sp_pos = [sp.x1, sp.y1, sp.z]
        sp.jobs.each {|job|
          # p [:job, job.id]
          next unless job.job_type == :StoreItemInStockpile
          raise "Whoa!" unless job.items.length == 1
          # next puts "Stale job" if job.expire_timer > 59000 # One we expired that has yet to be cleaned up
          item = job.items.first.item
          p [:item, item.id, item.pos, :job, job.id, job.pos]
          building = df.building_find(item.pos)
          type = building ? building_type_by_id(building.id).compact : [:Uncategorized]
          p [:building, building.id, [building.centerx, building.centery, building.z]] if building
          if building && building.id == sp.id
            $Pile = sp
            $Building = building
            $Job = job.inspect
            $Item = item
            df.pause_state = true
            df.cursor.x, df.cursor.y, df.cursor.z = item.pos.x, item.pos.y, item.pos.z
            raise "What!? Move #{item.getType} from ##{building.id} #{type} #{item.pos.inspect} to #{sp.id} - item already in Stockpile!"
          end
          location = "#{type.compact.join(', ')} at #{item.pos.inspect}"
          raise "Hey, this one has been here before! - Item #{item.id} in Stockpile #{sp.id}" if @item_ids[sp.id].include? item.id
          nx, ny, nz = sp.x1, sp.y1, sp.z
          puts "Moving #{item.getType} from #{location} to #{[nx, ny, nz].inspect}"
          item.pos.x, item.pos.y, item.pos.z = nx, ny, nz
          @item_ids[sp.id] << item.id
          @movements << {item.id => {[type, location] => sp.id}}
          job.expire_timer = 60000
          count += 1
        }
      }
      count
    end

    def analyze
      links = Hash.new {|h,k| h[k] = [] }

      # and track stops
      stockpiles.each {|sp|
        p [:sp, sp.id, sp.name, sp.getType]
        gp, tp, gw, tw = %w(give_to_pile take_from_pile give_to_workshop take_from_workshop).map {|n| sp.links.send(n).to_a }
        links[[sp.id, sp.name]]
        gp.each {|pl| links[[pl.id, pl.name]] << [:sp, sp.id, sp.name] }
        gw.each {|ws| links[[ws.id, ws.name]] << [:sw, sp.id, sp.name] }
        tp.each {|pl| links[[sp.id, sp.name]] << [:wp, pl.id, pl.name] }
        tw.each {|ws| links[[sp.id, sp.name]] << [:ww, ws.id, ws.name] }
      }

      links
    end

    # Links are {id => [id, id, id]}
    def pretty_print links
      links.each {|id, ids|
        type = building_type_by_id(id).compact.last
        source = "#{type} ##{id}"
        dests = ids.map {|id|
          type = building_type_by_id(id).compact.last
          "#{type} ##{id}"
        }
        p Hash[source, dests]
      }
      # .map {|k,a|
      # #   Hash[ [ (B(k).type rescue B(k).getType), k], a.sort.map {|id| [(B(id).type rescue B(id).getType), id] }]}.inject(&:merge).each {|k,vs| p Hash[k.join(' #'), vs.map {|v| v.join(' #') }.join(', ')] }
      # links.map {|id,a|
      #   # building = find_building_by_id id
      #   type = building_type_by_id id
      #   list = a.sort.map {|link_id| Hash[building_type_by_id(link_id), id] }
      #   Hash[[type, id], list]
      # }.inject(&:merge).map {|k,vs|
      #   key = k.join(' #')
      #   Hash[key, vs.map {|v| p v ; v.join(' #') }.join(', ')]
      # }
      #  Hash[
      #    [type, k, list.sort.map {|id|
      #    [(B(k).type rescue B(k).getType), k], a.sort.map {|id| [(B(id).type rescue B(id).getType), id] }]}.inject(&:merge).each {|k,vs| p Hash[k.join(' #'), vs.map {|v| v.join(' #') }.join(', ')] }

    end
  end
  ::DFZ = self unless const_defined? :DFZ
end

class DFHack::BuildingStockpilest
  # disable non-artifactable categories
  # try to enable artifactable cats - in the meantime, prompt
  # disable non-artifact qualities
  def setup_artifacts
    puts "Setting up artifacts pile"
    puts "Your artifacts pile should be named 'ArtifactsP'" if name != 'ArtifactsP'
    categories.each {|name, category|
      if category.respond_to? :quality_core
        next p [:please_enable, name] unless category.enabled?
        # category.enable
        category.allow_all
        category.quality_total[0...-1].each(&:disable)
      else
        category.disable
      end
    }
  end

  def set_no_artifacts
    puts "Your non-artifacts pile should NOT be named 'ArtifactsP'" if name == 'ArtifactsP'
    categories.each {|name, category|
      if category.respond_to? :quality_core
        category.quality_core.last.disable
        category.quality_total.last.disable
      end
    }
  end

  def set_kitchen
    puts "Your kitchen pile should be named 'KitchenP'" if name != 'KitchenP'
    puts "Setting up kitchen pile #{id}"
    food.all_items.each {|food|
      next food.disable unless food.respond_to? :edible_cooked?
      brewable = food.respond_to?(:brewable?) && food.brewable?
      food.set(food.edible_cooked? && !brewable)
    }
    food.glob_fat.each {|fat| fat.set(fat.token =~ /Tallow/) } # Leave the fat for the prep kitchen
    food.liquid_animal.each {|extract| extract.set(extract.token =~ /(Milk|Honey|Jelly)$/i && extract.token !~ /Dwarven/i) }
    food.seeds.each(&:disable) # technically cookable, but wasteful without proper management
    food.drink_plant.each(&:disable)
    food.drink_animal.each(&:disable)

    if !check_for_link 'Kitchen', type: :workshop
      puts "Your kitchen stockpile should be linked to a Kitchen named 'Kitchen'."
    end
  end

  def set_prep_kitchen
    puts "Your prep-kitchen pile should be named 'Prep KitchenP'" if name != 'Prep KitchenP'
    puts "Setting up prep-kitchen pile #{id}"
    food.block_all
    food.glob_fat.each {|fat| fat.set(fat.token =~ /Fat/) } # Turn fat into tallow

    if !check_for_link 'Prep Kitchen', type: :workshop
      puts "Your prep kitchen stockpile should be linked to a Kitchen named 'Prep Kitchen'."
    end
  end

  def set_brewery
    puts "Your brewery pile should be named 'BreweryP'" if name != 'BreweryP'
    puts "Setting up brewery #{id}"
    food.all_items.each {|food|
      next food.disable unless food.respond_to? :brewable?
      food.set food.brewable?
    }

    if !check_for_link 'Brewery', type: :workshop
      puts "Your brewery stockpile should be linked to a Still named 'Brewery'."
    end
  end

  def setup_by_name
    case name
    when 'KitchenP'      ; set_kitchen
    when 'Prep KitchenP' ; set_prep_kitchen
    when 'BreweryP'      ; set_brewery
    when 'ArtifactsP'    ; set_artifacts
    else ; # puts "Skipping unknown type of stockpile - id: #{id}, name: #{name}"
    end
    set_no_artifacts unless name == 'ArtifactsP'
  end
end

module DFStock
  def self.buildings_by_type type
    raise "No handler for #{type}" unless method = {stockpile: :STOCKPILE}[type]
    df.world.buildings.other.send(method)
  end

  def self.check_artifacts
    stockpiles = buildings_by_type(:stockpile)
    artifacts, regular = stockpiles.partition {|s| s.name =~ /artifacts/i }
    if artifacts.length > 1
      puts "You should only have one Artifacts stockpile"
      return false
    end
  end

  def self.check_for_stockpiles
    stockpiles = buildings_by_type(:stockpile)
    types = %w(kitchen prep_kitchen brewery artifacts)
    types.each {|type|
      pile_name = type.gsub(/_/,' ').split(/\s+/).map(&:capitalize).join(' ') + 'P'
      piles = stockpiles.select {|s| s.name == pile_name }
      puts "You should have a stockpile named #{pile_name}" if piles.empty?
    }
    true
  end

  def self.setup_stockpiles
    puts "Performing automatic name-based stockpile setup and linkage"

    check_for_stockpiles
    check_artifacts

    stockpiles = buildings_by_type(:stockpile)
    stockpiles.each &:setup_by_name
  end

  # # Name gives to Name2
  # def check_for_link name, name2
  # end
end

class ::DFHack::Building
  def get_links
    links = Hash.new {|h,k| h[k] = Hash.new {|h,k| h[k] = [] } }
    if respond_to? :links
      links[:stockpile][:give] =        self.links.give_to_pile.to_a
      links[:stockpile][:take] =        self.links.take_from_pile.to_a
      links[:workshop ][:give] =        self.links.give_to_workshop.to_a
      links[:workshop ][:take] =        self.links.take_from_workshop.to_a
    elsif respond_to? :getStockpileLinks
      links[:stockpile][:give] = getStockpileLinks.give_to_pile.to_a
      links[:stockpile][:take] = getStockpileLinks.take_from_pile.to_a
    end
    links
  end

  def check_for_link name, type: :stockpile, direction: :give
    method = (direction == :give ? 'give_to_' : 'take_from_') + (type == :stockpile ? 'pile' : 'workshop')
    all_links = send(getType == :Stockpile ? :links : :getStockpileLinks)
    links = all_links.send method
    links.any? {|link| link.name == name}
  end
end
