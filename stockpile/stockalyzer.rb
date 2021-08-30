# Analyzes stock flow into and out of shops, piles, and QSPs
module DFStockalyzer
  class << self
    def buildings ; df.world.buildings.all end

    def find_building_by_id        id ; buildings.find   {|b| b.id    == id    } end
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

      stockpiles.each {|sp|
        gp, tp, gw, tw = %w(give_to_pile take_from_pile give_to_workshop take_from_workshop).map {|n| sp.links.send(n).to_a }
        [gp, gw].flatten.each {|ws| links[sp.id] << ws.id }
                      tw.each {|ws| links[ws.id] << sp.id }
        [ sp.links.give_to_pile, sp.links.give_to_workshop].map {|wsl| wsl.flatten }.flatten.each {|ws| links[sp.id] << ws.id }
        sp.links.take_from_workshop.flatten.each {|ws| links[sp.id] << ws.id }
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
