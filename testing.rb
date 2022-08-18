module DFStock

  def self.testable_classes
    constants.map {|x|
      DFStock.const_get x
    }.select {|x|
      x.is_a?(Class) && x < DFStock::Thing
    }.sort_by {|x|
      x.to_s
    }
  end

  def self.test_all_classes
    testable_classes.map {|k| k.instances.last }.compact.each {|x| p x }
  end

  def self.test_all_categories pile
    pile ||= pile_at_cursor
    raise "Select a stockpile and enable all categories" unless pile
    pile.all_items.each(&:disable)
    pile.categories.each {|cn,s|
      s.features.select {|t,_,_,_| t == :array }.
      each {|_,n1, n2, o|
        sn = n2 || n1
        i = s.send(sn)
        next if i.empty?
        f, l = i.first, i.last
        [f,l].each &:enable
        p [cn, sn, [f,l].map(&:name)]
      }
    }
  end

  def self.test_all_comparators
    items = testable_classes.map(&:instances).flatten.compact
    puts "Checking comparators against #{items.length}"
    Comparators.instance_methods.sort.
      select {|mn| Comparators.instance_method(mn).arity.zero? }.
      each {|mn|
        num_rs = items.map(&mn).select {|x| next if x.respond_to?(:empty?) && x.empty? ; x }.length
        p [:Checking, mn, num_rs]
      }
  end

end
