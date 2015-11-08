require "io/console"

class Cursor
  attr_reader :pos

  MOVE_DIFFERENTIALS = {
    left: [0, -1],
    right: [0, 1],
    up: [-1, 0],
    down: [1, 0]
  }

  def initialize(start_pos)
    @pos = start_pos
    @after_move = Proc.new
    @validator = Proc.new { true }
  end

  def after_move(&after_move)
    @after_move = after_move
  end

  def validate_with(&validator)
    @validator = validator
  end

  def get_selection
    selection = nil

    until selection
      signal = Input::get_input
      if MOVE_DIFFERENTIALS.include?[signal]
        move(MOVE_DIFFERENTIALS[signal])
      elsif signal == :submit
        selection = @pos
      end
    end

    return selection
  end

  private

  def move(differential)
    new_pos = [@pos[0] + differential[0], @pos[1] + differential[1]]
    if valid_pos?(new_pos)
      @pos = new_pos
      @after_move.call(@pos)
    end
  end

  def valid_pos?(pos)
    @validator.call(pos)
  end
end

module Input
  KEYMAP = {
    " " => :space,
    "h" => :left,
    "j" => :down,
    "k" => :up,
    "l" => :right,
    "w" => :up,
    "a" => :left,
    "s" => :down,
    "d" => :right,
    "\t" => :tab,
    "\r" => :return,
    "\n" => :newline,
    "\e" => :escape,
    "\e[A" => :up,
    "\e[B" => :down,
    "\e[C" => :right,
    "\e[D" => :left,
    "\177" => :backspace,
    "\004" => :delete,
    "\u0003" => :ctrl_c,
  }

  def get_input
    key = KEYMAP[read_char]
    case key
    when :ctrl_c
      raise Interrupt.new
    when :return, :space
      :submit
    when :left, :right, :up, :down
      key
    end
  end

  def read_char
    STDIN.echo = false
    STDIN.raw!

    input = STDIN.getc.chr
    if input == "\e" then
      input << STDIN.read_nonblock(3) rescue nil
      input << STDIN.read_nonblock(2) rescue nil
    end
  ensure
    STDIN.echo = true
    STDIN.cooked!

    return input
  end
end
