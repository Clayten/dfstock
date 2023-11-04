module DFStock

  # Every class of thing that appears in the stock menus
  def self.testable_classes
    constants.map {|x|
      DFStock.const_get x
    }.select {|x|
      x.is_a?(Class) && x < DFStock::Thing
    }.sort_by {|x|
      x.to_s
    }
  end

  # Every thing that exists in the stock menus
  def self.testable_items
    items = testable_classes.map(&:instances).flatten.uniq
  end

  # Every (added) way to compare two objects
  def self.testable_comparators
    Comparators.
      instance_methods.
      select {|mn|
        Comparators.instance_method(mn).arity.zero?
      }.
      sort
  end

  # Creates abstract instance of each class
  def self.test_all_classes
    testable_classes.map {|k| k.instances.last }.compact.each {|x| p x }
    true
  end

  # Enable only the first and last item in all categories in a pile
  def self.test_all_categories pile
    pile ||= pile_at_cursor
    raise "Select a stockpile and enable all categories" unless pile
    pile.categories.each {|cn,c|
      begin
        c.enable
      rescue NotImplementedError
        next p "Category #{cn} - unable to enable"
      rescue
        raise
      end
      # next unless (c.enable rescue false)
      c.all_items.each {|i|
        i.disable
      }
      next unless c.respond_to? :features # such as corpses, without any items or categories
      c.features.select {|t,_,_,_| t == :array }.
      each {|_,n1, n2, o|
        sn = n2 || n1
        i = c.send(sn)
        next if i.empty?
        f, l = i.first, i.last
        [f,l].each &:enable
        p [cn, sn, [f,l].map(&:name)]
      }
    }
    true
  end

  # Calls all comparators on all abstract items
  def self.test_all_comparators
    items = testable_items
    puts "Checking comparators against #{items.length}"
    testable_comparators.each {|mn|
      t = items.map(&mn).select {|x| !!x }.length
      f = items.map(&mn).select {|x| x == false }.length
      n = items.map(&mn).select {|x| x.nil? }.length
      puts "Checking #{'%22s' % mn}, t: #{'%5d' % t}, f: #{'%5d' % f}, n: #{'%5d' % n}"
    }
    true
  end

end
