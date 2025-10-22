# File: src/terminal/wait_group.cr
# Purpose: Simple wait group implementation for coordinating fibers

module Terminal
  class WaitGroup
    def initialize
      @counter = 0
      @mutex = Mutex.new
      @done = Channel(Nil).new(1)
    end

    def add
      @mutex.synchronize do
        if @counter == 0
          # reset the done channel when transitioning from idle to active
          @done = Channel(Nil).new(1)
        end
        @counter += 1
      end
    end

    def done
      to_signal = false
      @mutex.synchronize do
        @counter -= 1
        @counter = 0 if @counter < 0
        to_signal = (@counter == 0)
      end
      if to_signal
        @done.send(nil) rescue nil
      end
    end

    def wait(timeout : Time::Span? = nil)
      # If there is nothing to wait for, return immediately
      return true if count == 0

      if timeout
        select
        when @done.receive
          true
        when timeout(timeout.not_nil!)
          false
        end
      else
        @done.receive
        true
      end
    end

    def count
      @mutex.synchronize { @counter }
    end
  end
end
