
module DFStockalyzer
  # extend DwarfFortressUtils::API
  class << self

    def find_building_by_id id ; buildings.find {|b| b.id == id } end
    def building_type_by_id id
      building = find_building_by_id id
      [building.getType, (building.type rescue nil)]
    end

    def stockpiles ; buildings_by_type :stockpile end
    def trackstops ; buildings_by_type :trackstop end

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
      linkables = buildings.select {|b| b.respond_to? :get_links }

      display_cursor = false
      # Piles and Workshops and Trackstops should be named
      linkables.each {|l|
        next unless l.name.empty?
        next if l.get_links.values.map(&:values).flatten.empty?  # Don't mention a building/workshop/trackstop unless it has links
        display_cursor = p [:analyze, df.cursor] unless display_cursor
        puts "WARN: #{l.class} at x:#{l.x1},y:#{l.y1} on z:#{l.z} is unnamed"
      }

      links = Hash.new {|h,k| h[k] = [] }

      # and track stops
      linkables.each {|l|
        name = !l.name.empty? ? l.name : "#{l.class} #{l.id}"
        # p [:linkable, l.class, l.name, l.getType]
        l.get_links.each {|type, sub_links|
          sub_links.each {|dir, link_names|
            link_names.each {|link|
              link_name = link.name
              links[[name, dir]] << link_name
            }
          }
        }
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

# DFHack::BuildingStockpilest
#   set_artifacts / etc
#   setup_by_name
#
# DFStock
#   buildings_by_type
#   check_artifacts
#   check_for_stockpiles
#   setup_stockpiles
#
# Building
#   get_links
#   check_for_link
#
# Run DFHack, call 'rb DFStock.setup_stockpiles', add and name piles, QSP piles, and workshops, as requested. rerun command until finished
#

if self.class.const_defined? :DFHack
  class DFHack::BuildingStockpilest
    # module Bar
    #   def bar ; end
    # end
    # include Bar

    module PileSetup
      # disable non-artifactable categories
      # try to enable artifactable cats - in the meantime, prompt
      # disable non-artifact qualities
      def set_artifacts
        raise "Artifacts pile should be named 'Artifacts'" unless name == 'Artifacts'
        puts "Setting up artifacts pile #{id}"
        self.max_wheelbarrows = 0 # It might slow down a large furniture, but should speed up all other artifact placements
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
        raise "Non-artifacts pile should NOT be named 'Artifacts'" if name == 'Artifacts'
        categories.each {|name, category|
          if category.respond_to? :quality_core
            category.quality_core.last.disable
            category.quality_total.last.disable
          end
        }
        true
      end

      def set_kitchen
        raise "Kitchen pile should be named 'Kitchen'" unless name == 'Kitchen'
        puts "Setting up kitchen pile #{id}"
        self.max_wheelbarrows = 0
        food.all_other_categories.each &:disable
        food.all_items.each {|food|
          next food.disable unless food.respond_to? :edible_cooked?
          brewable = food.respond_to?(:brewable?) && food.brewable?
          food.set(food.edible_cooked? && !brewable)
        }
        food.glob_fat.each {|fat| fat.set(fat.name =~ /Tallow/) } # Leave the fat for the prep kitchen
        food.liquid_animal.each {|extract| extract.set(extract.name =~ /(Milk|Honey|Jelly)$/i && extract.name !~ /Dwarven/i) }
        food.seeds.each(&:disable) # technically cookable, but wasteful without proper management
        food.drink_plant.each(&:disable)
        food.drink_animal.each(&:disable)

        if !check_for_link 'Kitchen', type: :workshop
          puts "Kitchen stockpile should be linked to a kitchen named 'Kitchen'."
        end
      end

      def set_prep_kitchen
        raise "Prep-kitchen pile should be named 'Prep Kitchen'" unless name == 'Prep Kitchen'
        puts "Setting up prep-kitchen pile #{id}"
        self.max_wheelbarrows = 0
        food.all_other_categories.each &:disable
        food.block_all
        food.glob_fat.each {|fat| fat.set(fat.name =~ /Fat/) } # Turn fat into tallow
        if !check_for_link 'Prep Kitchen', type: :workshop
          puts "Prep kitchen stockpile should be linked to a kitchen named 'Prep Kitchen'."
        end
      end

      def set_brewery_plants
        raise "Brewery plants pile should be named 'Brewery Plants'" unless name == 'Brewery Plants'
        puts "Setting up brewery plants #{id}"
        self.max_wheelbarrows = 0
        food.all_other_categories.each &:disable
        food.all_items.each {|food|
          next food.disable unless food.respond_to? :brewable?
          food.set food.brewable?
        }
        if !check_for_link 'Brewery', type: :workshop
          puts "Brewery plants stockpile should be linked to a Still named 'Brewery'."
        end
      end

      def set_brewery_barrels
        raise "Brewery barrels pile should be named 'Brewery Barrels'" unless name == 'Brewery Barrels'
        puts "Setting up brewery barrels #{id}"
        self.max_wheelbarrows = 0
        furniture.all_other_categories.each &:disable
        furniture.type.each &:disable
        furniture.type.find {|f| f.name == 'Barrel' }.enable
        furniture.type.find {|f| f.name == 'Food Storage' }.enable # Large Pots
        if !check_for_link 'Brewery', type: :workshop
          puts "Brewery barrels stockpile should be linked to a Still named 'Brewery'."
        end
      end

      def check_qsp
         name =~ /QSP$/
      end

      def setup_by_name
        case name
        when 'Kitchen'         ; set_kitchen
        when 'Prep Kitchen'    ; set_prep_kitchen
        when 'Brewery Plants'  ; set_brewery_plants
        when 'Brewery Barrels' ; set_brewery_barrels
        when 'Artifacts'       ; set_artifacts
        else ; puts "Skipping unknown type of stockpile - id: #{id}, name: #{name}, Pos: #{x1},#{y1} to #{x2},#{y2} on z: #{z}"
        end
        set_no_artifacts unless name == 'Artifacts'
      end
    end
    include PileSetup
  end
end

module DFStock
  def self.buildings_by_type type
    raise "No handler for #{type}" unless method = {stockpile: :STOCKPILE}[type]
    df.world.buildings.other.send(method)
  end

  def self.check_artifacts
    stockpiles = buildings_by_type(:stockpile)
    artifacts, regular = stockpiles.partition {|s| s.name =~ /^artifactsp$/i }
    if artifacts.length > 1
      puts "There should only be one Artifacts stockpile"
      return false
    end
  end

  def self.check_for_stockpiles
    stockpiles = buildings_by_type(:stockpile)
    types = %w(kitchen prep_kitchen brewery_plants brewery_barrels artifacts)
    types.each {|type|
      pile_name = type.gsub(/_/,' ').split(/\s+/).map(&:capitalize).join(' ')
      piles = stockpiles.select {|s| s.name == pile_name }
      puts "There should be a stockpile named #{pile_name}" if piles.empty?
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

module DFHack
  module Linkable
    # Check for a link between this pile and a pile or workshop with a given name
    #
    # By default, an indirect link via a Quantum Storage Pile is allowed, if the QSP is called
    # the same as the source pile + 'QSP', and the QSP links to the desired target.
    #
    # To specifically check that a QSP is not used, set allow_qsp: false
    # To specifically check for a QSP, use its full name, set allow_qsp: false, and check the give and take links manually
    def check_for_link link_name, target_type: :stockpile, direction: :give, allow_qsp: true, return_link: false
      # p [:check_for_link, name, direction, link_name, :allow_qsp, allow_qsp]
      raise "Incorrect usage, pile name or target pile name contains 'QSP' and allow_qsp is true." if allow_qsp && (name =~ /QSP$/ || link_name =~ /QSP$/)
      raise "Incorrect usage, target_type must be :workshop or :stockpile" unless [:workshop, :stockpile].include? target_type
      raise "Incorrect usage, direction must be :give or :take" unless [:give, :take].include? direction

      links = get_links[target_type][direction]

      link = links.find {|link| link.name == link_name }
      return (return_link ? link : true) if link

      return false unless allow_qsp
      if direction == :give
        return false unless link = check_for_link(     "#{name}QSP",  target_type: :stockpile,  direction: :give, allow_qsp: false, return_link: true)
                              link.check_for_link(   link_name,       target_type: target_type, direction: :give, allow_qsp: false, return_link: return_link)
      else
        return false unless link = check_for_link("#{link_name}QSP",  target_type: :stockpile,  direction: :take, allow_qsp: false, return_link: true)
                              link.check_for_link(   link_name,       target_type: target_type, direction: :take, allow_qsp: false, return_link: return_link)
      end
    end
  end

  class HaulingStop ; include Linkable end
  class BuildingStockpilest ; include Linkable end
  class BuildingWorkshopst ; include Linkable end
end

module DFStock
  def self.analyze_stockpiles
    stockpiles.each {|pile|
      $p = pile
      links = pile.get_links
      targets = links[:stockpile][:give] + links[:hauling][:give]
      next if pile.enabled_pathnames.length.zero?
      next if targets.empty?
      puts "Pile #{pile.name} at #{pile.x1},#{pile.y1},#{pile.z} feeds into #{targets.length} targets: #{targets.map(&:name).join(', ')}"
      # next puts "\thas no outputs - will retain everything" if targets.empty?
      leftover = targets.inject(pile) {|a,b| a - b }
      puts "\thas #{leftover.length} stuck stock item-types out of #{pile.enabled_pathnames.length}"
    }
    true
  end
end
