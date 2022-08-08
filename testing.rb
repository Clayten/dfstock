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

  def self.test
    testable_classes.map {|x|
      p [:Creating, x]
      l = x.index_translation.length
      next if l.zero?
      x.new(l - 1)
    }.compact.map {|x|
      p x
    }
  end

end
