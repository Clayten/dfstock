# DFStock - Query and Settings Tools for Dwarf Fortress

Query item-class properties to sort, select, and stockpile programmatically.

Lets you fully enable/disable items, select categories, items, and qualities, and link to workshops,other stockpiles, and track stops.

Analyze your network of stockpiles, see likely problems and solutions, generate graphs.

Has template stockpiles that are commonly used - 'weapons grade ore', 'good weapons', 'cookable food', 'above-ground seeds', etc.

DFStock creates stockpile items as Ruby objects for programmatic querying. You can sort woods by density, stones by color, and foods that need to be cooked.

These settings can also applied to a given settings pile (or track stop) and added and removed from other stockpiles. Track stops can be configured exactly the same as stockpiles, allowing for automated creation of hauling routes and quantum stockpiles.

DFStock supports custom, modded, and generated items by querying dfhack and enumerating all dwarf fortress objects at each map load.

## About

The DFStock project is a Ruby DFHack script, aiming at eventual inclusion in the dfhack project after fixes and feedback.

## Installation and Loading

```shell
# Fetch the latest code
git clone git@github.com:Clayten/dfstock.git

# Set DFHack to reload DFStock at each map load
echo "rb load 'dfstock'" >> ~/df/onLoad-dfstock.init

# start dwarf via dfhack
./dfhack
```

## Usage
Note: All dfhack console commands must be preceeded with 'rb ' to execute a Ruby command. This is left out of the examples for brevity.

(There will be dfhack commands once integrated, such as 'dfstock graph' which are meant to be used manually or bound to a key, not as code, but at this point in development they aren't finalized and must be run via Ruby.)

Query items by type and properties - shows that some items have more parts (seeds, leaves, fruit, extract) than others, and which categories those are in.
```dfhack
p DFStock::Tree.instances.sort_by {|t| t.material.solid_density }.last(5)

 [#<DFStock::Tree name="olive trees" fruitleaf_index=57 plant_index=156 plantextract_index=4 pressed_index=4 seed_index=116 link_index=156 tree_index=25>,
  #<DFStock::Tree name="abaca trees" plant_index=131 seed_index=91 link_index=131 tree_index=0>,
  #<DFStock::Tree name="banana trees" fruitleaf_index=34 plant_index=132 plantdrink_index=41 seed_index=92 link_index=132 tree_index=1>,
  #<DFStock::Tree name="glumprongs" plant_index=211 link_index=211 tree_index=59>,
  #<DFStock::Tree name="blood thorn" plant_index=210 link_index=210 tree_index=58>]
```

Query/Set a given stockpile's item acceptance, based on item properties
```dfhack
# Select the target stockpile by arrowing over it in Dwarf Fortress's UI and running this command
# The variable can be used after linkage even if the cursor is moved
MyPile = pile_at_cursor

MyPile.food.enable                              # Enable the food category
MyPile.food.seeds.each {|s| s.set s.edible? }   # only accept seeds we can eat
```

Query items by stock category
```dfhack
pile_at_cursor.categories.map {|name, settings| num = settings.enabled_pathnames.length ; p [name, num] }

        ["animals", 0]
        ["food", 0]
        ["furniture", 100]
        ...
```

Display a stockpile settings-summary
```dfhack
pile_at_cursor.status

        Stockpile #92 - "Good Furniture"
        # Max Barrels: 0 - # Max Bins: 0 - # Max Wheelbarrows: 0
        # of Containers: 0, bins: 0, barrels: 0
        Mode: Use Links Only
        Linked Stops: 0
        Incoming Stockpile Links: 2 - Furniture, Main Collector
        Outgoing Workshop Links: 1 - Jewelers
        StockSelection:
                Allow Organics: true
                Allow Inorganics: true
                   furniture true - 100 items enabled
```

## Examples

Make sure all items in a pile have another stockpile to flow into and don't get split amongst many
stockpiles or carried and transfered multiple times.

```dfhack
# Create four stockpiles in the DF UI, the first is FoodIncoming. Set it give to give to three more stockpiles
# we'll call EdibleRaw, NeedsCooking, and NotFood, and set the later three to take from 'Links Only'.

FoodIncoming = pile_at_cursor
FoodIncoming.food.enable       # Enable the food category
FoodIncoming.food.allow_all    #   and allow all food items

# This will hold food which is edible raw, perhaps to keep snackable items near the dwarves.
EdibleRaw = pile_at_cursor  # Arrow over the raw stockpile to create a variable referencing it
EdibleRaw.food.enable       # Enable the class of food items but don't allow any items yet
EdibleRaw.food.all_items.each {|s| s.set s.edible_raw? } # accept things we can eat without cooking

# This holds food-category items you don't want near your kitchens
NotFood = pile_at_cursor  # Arrow over the not-food stockpile
NotFood.food.enable       # Enable the class of food items but don't allow any items yet
NotFood.food.all_items.each {|s| s.set !s.edible? } # accept things we can not eat. Lye, etc.

# This goes near the kitchens and stills for maximum worker efficiency
NeedsCooking = pile_at_cursor # Select the next stockpile, which should be near the kitchens
NeedsCooking.copy(FoodIncoming - EdibleRaw - NotFood) # Set the pile to take all items from FoodIncoming
                                                      # except those which belong in EdibleRaw and NotFood
```

## Future Directions

Bug fixes, non-programmatic commands, DFHack integration.

Much of the mod, by definition, is a programming tool. But the goal is to implement commands in it to diagnose the entire stockpile network; graphing flows, checking for stuck or lost items that don't have a proper destination, checking quantum stockpile for correct construction, etc.

DFHack integration also requires meeting their script requirements. Proper documentation blocks, specific coding standards, etc.

## Contributing

Coding, testing, and ideas are all required and appreciated. Both for DFStock and for derivative projects like DFStockalyzer.
