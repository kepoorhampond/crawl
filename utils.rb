$ids = []

def gen_id
  id = rand(0..100000)
  if !$ids.include?(id)
    $ids.push(id)
    return id
  end
end


def box(params={width: 10, height: 10, x: 10, y: 10})
  (0..params[:width]).each do |n| # horizontal blocks
    @map.place_object(params[:x] + n, params[:y], 'wall')
    @map.place_object(params[:x] + n, params[:y] + params[:height], 'wall')
  end
  (0..params[:height]).each do |n| # vertical blocks
    @map.place_object(params[:x] + params[:width], params[:y] + n, 'wall')
    @map.place_object(params[:x], params[:y] + n, 'wall')
  end
end

def object_controls(object)
  if Time.new - @move_timer > 0.06
    @move_timer = Time.new
    if Gosu::button_down?(Gosu::KbUp)
      object[:y] -= 1 if @map.valid_movement?([0,-1], object)
      return true
    end
    if Gosu::button_down?(Gosu::KbDown)
      object[:y] += 1 if @map.valid_movement?([0,1], object)
      return true
    end
    if Gosu::button_down?(Gosu::KbLeft)
      object[:x] -= 1 if @map.valid_movement?([-1,0], object)
      return true
    end
    if Gosu::button_down?(Gosu::KbRight)
      object[:x] += 1 if @map.valid_movement?([1,0], object)
      return true
    end
  end
end

def default_definitions()
  @map.define_object("wall", {
    symbol: "#",
    type: 'block'
  })
  @map.define_object("exit", {
    symbol: ">",
    type: "dynamic",
    color: Gosu::Color::rgb(0, 232, 255),
    behavior: -> {
      if @map.colliding?(@map.player, @map.get_object_by_name("exit"))
        @window.next_level
      end
    }
  })
  @map.define_object("teleporter", {
    # requires a `target_x` and `target_y` as arguments
    symbol: "O",
    type: "dynamic",
    color: Gosu::Color::rgb(0, 255, 0),
    behavior: ->(args) {
      me = @map.get_object(args[:x], args[:y])
      if @map.colliding?(@map.player, me)
        @map.player[:x] = args[:target_x]
        @map.player[:y] = args[:target_y]
      end
    },
  })
  @map.define_object("npc", {
    # takes the arguments :symbol, :id, :text
    symbol: "N",
    type: "block",
    behavior: ->(args) {
      talk(args[:text], args[:id], args[:text_opts])
    },
    initialize: ->(args) {
      @map.get_object_by_id(args[:id])[:symbol] = args[:symbol] unless\
        args[:symbol].nil?
      @map.get_object_by_id(args[:id])[:color] = args[:color] unless\
        args[:color].nil?
    }
  })
end

def chase_psychopathically(obj1, obj2)
  x_dif = [obj1[:x], obj2[:x]].max - [obj1[:x], obj2[:x]].min
  y_dif = [obj1[:y], obj2[:y]].max - [obj1[:y], obj2[:y]].min
  if x_dif > y_dif
    if obj1[:x] < obj2[:x] and @map.valid_movement?([1, 0], obj1)
      obj1[:x] += 1
    elsif obj1[:x] > obj2[:x] and @map.valid_movement?([-1, 0], obj1)
      obj1[:x] += -1
    end
  elsif x_dif < y_dif
    if obj1[:y] < obj2[:y] and @map.valid_movement?([0, 1], obj1)
      obj1[:y] += 1
    elsif obj1[:y] > obj2[:y] and @map.valid_movement?([0, -1], obj1)
      obj1[:y] += -1
    end
  end
end

def chase(obj1, obj2)
  left_dist = obj1[:x] - obj2[:x]
  up_dist = obj1[:y] - obj2[:y]

  if (up_dist == 0 and left_dist == 0)
    return
  end
  if (up_dist > 0 and up_dist >= left_dist) and @map.valid_movement?([0, -1], obj1)
    obj1[:y] += -1
  elsif (up_dist < 0 and up_dist < left_dist) and @map.valid_movement?([0, 1], obj1)
    obj1[:y] += 1
  elsif (left_dist > 0 and left_dist >= up_dist) and @map.valid_movement?([-1, 0], obj1)
    obj1[:x] += -1
  elsif @map.valid_movement?([1, 0], obj1)
    obj1[:x] += 1
  end
end

def killed_by(words)
  @window.set_pending("pend_killed_by", [@window, words])
end

def pend_killed_by(args)
  #window.clear
  args[0].map.reset
  args[0].map.create_from_grid(15, 10, [
    "    _____ ",
    "   /     \\",
    "   I RIP I",
    "   I  @  I",
    "   I     I",
    "   I___V_I",
    " Y/.W..|./",
    " |..|.../",
    "/______/"], {
      "@" => ["player"],
      "V" => {color: Gosu::Color::rgb(200, 0, 0)},
      "W" => {color: Gosu::Color::rgb(146, 101, 173)},
      "Y" => {color: Gosu::Color::rgb(252, 237, 100)},
      "|" => {color: Gosu::Color::rgb(0, 179, 18)},
      "." => {color: Gosu::Color::rgb(88, 47, 37)},
    }
  )
  args[0].new_text(args[1], {y_loc: 0.1, new_line: 50, sound: "text.wav", id: "death"})
end

def kill_player_if_touching(id, words)
  if @map.colliding?(@map.get_object_by_id(id), @map.player)
    killed_by(words)
  end
end

def distance_from(obj1, obj2)
  Math.sqrt( ((obj1[:x] - obj2[:x]) ** 2) + ((obj1[:y] - obj2[:y]) ** 2) )
end

def talk(words, id, opts={})
  opts = {} if opts == nil
  # make an elseif statement so that it doesnt place this a lot and can be dismissed by pressing `A`
  if @map.are_touching?(@map.get_object_by_id(id), @map.player)
    if @window.get_text_by_id(id) == false
      @window.new_text(words, {sound: "text.wav", id: id}.merge(opts))
    end
  elsif @window.get_text_by_id(id)
    @window.texts.delete_at(@window.texts.index(@window.get_text_by_id(id)))
  end
end
