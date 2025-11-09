require "wait_group"

module Terminal
  # Thin wrapper around the stdlib WaitGroup that adds optional timeout support.
  class TimedWaitGroup
    def initialize
      @wait_group = ::WaitGroup.new
    end

    def add(n : Int32 = 1)
      @wait_group.add(n)
    end

    def done
      @wait_group.done
    end

    def wait(timeout : Time::Span? = nil) : Bool
      return wait_without_timeout if timeout.nil?

      finished = Channel(Nil).new(1)
      spawn do
        @wait_group.wait
        finished.send(nil)
      end

      select
      when finished.receive
        true
      when timeout(timeout.not_nil!)
        false
      end
    end

    private def wait_without_timeout : Bool
      @wait_group.wait
      true
    end
  end
end
