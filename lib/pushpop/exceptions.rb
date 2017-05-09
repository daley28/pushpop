module Pushpop
  class Error < RuntimeError
  end

  class DuplicateStepNameError < Error
    def initialize(step)
      @step = step
      msg = "Duplicate step name '#{step.name}'."
      super(msg)
    end
  end
end
