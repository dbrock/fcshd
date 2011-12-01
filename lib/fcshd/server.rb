require "socket"

module FCSHD
  class Server
    PORT = 34345

    def initialize(port, compiler, logger)
      @server = TCPServer.new("localhost", port)
      @compiler = compiler
      @logger = logger
    end

    def run!
      loop do
        Thread.start(@server.accept) do |socket|
          Client.new(socket, @compiler).run!
        end
      end
    end

    class Client < Struct.new(:socket, :compiler)
      def run!
        case command = socket.gets
        when /^(mxmlc|compc) /
          compiler.compile! command, socket
        else
          socket.puts "fcshd: unrecognized command: #{command}"
        end
      rescue Errno::EPIPE
        logger.log "Broken pipe."
      ensure
        socket.close
      end
    end
  end
end
