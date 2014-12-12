class Player
  attr_reader :queue, :now_playing, :volume

  def initialize(volume: 1)
    @queue = []
    @cmd_rd, @cmd_wr = IO.pipe
    @cmds = []
    @volume = volume
  end

  def enqueue(file)
    queue << file
    send_message("enqueued")
  end

  def skip
    send_message("skip")
  end

  def start_player_thread
    @thread = Thread.start { player_thread }
  end

private
  def send_message(msg)
    @cmds << msg
    @cmd_wr.write(".")
    @cmd_wr.flush
  end

  def player_thread
    afplay = nil

    loop do
      ready, _, _ = IO.select([@cmd_rd, afplay].compact)

      if ready.include?(afplay) || afplay.nil?
        if @now_playing = queue.shift
          afplay = IO.popen(["afplay", "-v", volume.to_s, now_playing])
        end
      end

      if ready.include?(@cmd_rd)
        @cmd_rd.read(1)
        case @cmds.shift
        when "skip"
          Process.kill(:KILL, afplay.pid) if afplay
        when "enqueued"
          # pass
        end
      end
    end
  rescue => e
    $stderr.puts "#{e.class}: #{e.message}"
    $stderr.puts e.backtrace
  ensure
    Process.kill(:KILL, afplay.pid) if afplay.pid
  end
end
