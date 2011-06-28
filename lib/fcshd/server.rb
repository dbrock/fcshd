require "socket"

module FCSHD
  class Server
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
        when /^mxmlc /
          output compiler.compile!(command)
        when /^restart$/
          output compiler.restart!
        else
          error "Unrecognized command: #{command}"
        end
      rescue Errno::EPIPE
        logger.log "Broken pipe."
      end

      def output(content)
        socket.print(content)
        socket.close
      end

      def error(message)
        socket.puts "fcshd: #{message}"
        socket.close
      end
    end
  end
end
