require "socket"

module FCSHD
  class Server
    def initialize(port, compiler, logger)
      Thread.abort_on_exception = true
      @server = TCPServer.new("localhost", port)
      @compiler = compiler
      @logger = logger
    end

    def run!
      loop do
        socket = @server.accept
        @logger.log "Accepted connection."
        Thread.start(socket) do |socket|
          Client.new(socket, @compiler).run!
        end
      end
    end

    class Client < Struct.new(:socket, :compiler)
      def run!
        case command = socket.gets
        when /^mxmlc /
          output compiler.compile!(command)
        when /^restart$/
          output compiler.restart!
        else
          error "unrecognized command: #{command}"
        end
      end

      def output(content)
        socket.print(content)
        socket.close
      end

      def error(message)
        socket.puts "fcshd: error: #{message}"
        socket.close
      end
    end
  end
end
