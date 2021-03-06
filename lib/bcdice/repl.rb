require "bcdice"
require "readline"

module BCDice
  class REPL
    class << self
      def run(history_path)
        REPL.new(history_path).run()
      end
    end

    def initialize()
      @game_system = GameSystem::DiceBot
      @hisoty_file = nil
      @debug = false
    end

    attr_writer :debug

    def history_file=(path)
      @hisoty_file = path

      if File.exist?(@hisoty_file)
        File.open(@hisoty_file) do |f|
          history = f.readlines.map(&:chomp)
          Readline::HISTORY.push(*history)
        end
      end
    end

    def quit
      if @hisoty_file
        last_100_comamnds = Readline::HISTORY.to_a.reverse[0, 100].reverse
        File.write(@hisoty_file, last_100_comamnds.join("\n"))
      end

      exit
    end

    def run
      puts "BCDice REPL"
      puts '>> "help" shows help messages.'
      loop do
        run_once()
      end
    end

    def run_once
      input = Readline.readline(header())&.strip
      unless input
        puts
        return
      end

      if input.empty?
        return
      end

      Readline::HISTORY.push(input)
      eval_command(input)
    rescue Interrupt
      quit()
    end

    def header()
      debug_mode = "(Debug) " if @debug
      "[#{debug_mode}#{@game_system::ID}]> "
    end

    def eval_command(input)
      args = input.split(" ")
      if args.empty?
        return
      end

      command = args.shift

      block = REPL.commands[command]
      if block
        block.call(self, *args)
      else
        eval_game_system(command)
      end
    end

    class << self
      attr_reader :commands

      def command(*name, &block)
        @commands ||= {}
        name.each do |key|
          @commands[key] = block
        end
      end
    end

    command "use", "set" do |repl, game_system|
      repl.load_game_system(game_system)
    end

    command "debug" do |repl, mode|
      repl.debug = !["off", "false"].include?(mode&.downcase)
    end

    command "history" do
      puts Readline::HISTORY.to_a
    end

    command "help" do
      puts <<~HELP
        BCDice REPL commands:
          use GAME_SYSTEM      # 使うゲームシステムを指定する
          set GAME_SYSTEM      # 同上
          debug [on, off]      # Debugモードの切替
          debug [true, false]  # 同上
          history              # コマンド履歴を表示
          help                 # このメッセージを表示する
          exit, quit, q        # REPLを終了する
      HELP
    end

    command "exit", "quit", "q" do |repl|
      repl.quit()
    end

    def eval_game_system(command)
      gs = @game_system.new
      gs.enable_debug if @debug
      puts gs.eval(command)
    rescue StandardError => e
      puts e
      puts e.backtrace
    end

    def load_game_system(game_system)
      klass = BCDice.dynamic_load(game_system)
      if klass
        @game_system = klass
      else
        puts "#{game_system.inspect} not found"
      end
    end

    alias game_system= load_game_system
  end
end
