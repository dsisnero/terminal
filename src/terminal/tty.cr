# Shared terminal helpers (TTY mode management).
# Provides minimal raw-mode toggling so synchronous prompts and async input
# providers can share the same termios logic.

require "io"

module Terminal
  module TTY
    # Runs the given block with the file descriptor placed in raw mode.
    # If the IO is not a TTY or lacks a descriptor, the block runs unchanged.
    def self.with_raw_mode(io : IO = STDIN, non_blocking : Bool = false, &block)
      if fd = io.as?(IO::FileDescriptor)
        with_raw_mode_fd(fd, non_blocking: non_blocking) { yield }
      else
        yield
      end
    end

    {% unless flag?(:win32) %}
      TCSANOW    =      0
      F_GETFL    =      3
      F_SETFL    =      4
      O_NONBLOCK = 0x0004

      private def self.with_raw_mode_fd(io : IO::FileDescriptor, non_blocking : Bool, &block)
        if io.tty?
          orig = uninitialized LibC::Termios
          raw = uninitialized LibC::Termios
          flags = 0

          LibC.tcgetattr(io.fd, pointerof(orig))
          raw = orig
          LibC.cfmakeraw(pointerof(raw))
          LibC.tcsetattr(io.fd, TCSANOW, pointerof(raw))

          if non_blocking
            flags = LibC.fcntl(io.fd, F_GETFL, 0)
            LibC.fcntl(io.fd, F_SETFL, flags | O_NONBLOCK)
          end

          begin
            yield
          ensure
            if non_blocking
              LibC.fcntl(io.fd, F_SETFL, flags)
            end
            LibC.tcsetattr(io.fd, TCSANOW, pointerof(orig))
          end
        else
          yield
        end
      end
    {% else %}
      lib Win
        alias HANDLE = Void*
        alias DWORD = UInt32
        alias BOOL = Int32

        fun GetStdHandle(nStdHandle : DWORD) : HANDLE
        fun GetConsoleMode(hConsoleHandle : HANDLE, lpMode : DWORD*) : BOOL
        fun SetConsoleMode(hConsoleHandle : HANDLE, dwMode : DWORD) : BOOL

        STD_INPUT_HANDLE              = 0xFFFFFFF6_u32
        ENABLE_VIRTUAL_TERMINAL_INPUT =     0x0200_u32
        ENABLE_PROCESSED_INPUT        =     0x0001_u32
        ENABLE_LINE_INPUT             =     0x0002_u32
        ENABLE_ECHO_INPUT             =     0x0004_u32
      end

      private def self.with_raw_mode_fd(io : IO::FileDescriptor, non_blocking : Bool, &block)
        if io.tty?
          handle = io.fd == 0 ? Win.GetStdHandle(Win::STD_INPUT_HANDLE) : nil
          return yield unless handle
          mode = uninitialized Win::DWORD
          Win.GetConsoleMode(handle, pointerof(mode))

          new_mode = mode | Win::ENABLE_VIRTUAL_TERMINAL_INPUT | Win::ENABLE_PROCESSED_INPUT
          new_mode &= ~(Win::ENABLE_ECHO_INPUT | Win::ENABLE_LINE_INPUT)

          Win.SetConsoleMode(handle, new_mode)
          begin
            yield
          ensure
            Win.SetConsoleMode(handle, mode)
          end
        else
          yield
        end
      end
    {% end %}
  end
end
