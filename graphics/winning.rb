require 'gosu'
require_relative '../conversation.rb'

class Winning
  def initialize(window)
    @window = window
    @char = Gosu::Image.new("./graphics/winning.png")
    @text = Text.new(@window, "You won! You got the round gray orb! You killed a hundreds of peaceful aliens!
", "courier.ttf", 36, {
      y_loc: 0.9,
      sound: "./text.wav",
      right_border: @window.width * 0.9,
      new_line: 36,
    })
    @text1 = Text.new(@window, "\n...You're a monster.
", "courier.ttf", 36, {
      y_loc: 0.9,
      x_loc: 0.35,
      sound: "./text.wav",
      right_border: @window.width * 0.9,
      new_line: 36,
      delay: 20,
    })
    @orb = Gosu::Image.new("./graphics/o.png")
    @orb_offset_x = 0
    @orb_offset_y = 0
    @orb_num = -1
    @orb_num1 = 0
    @change = 0.1
  end
  def draw
    @text.draw
    @text1.draw
    @char.draw(@window.width / 2.7, @window.height / 7, 1, 0.75, 0.75)
    @orb.draw(@window.width / 3.5 + @orb_offset_x, @window.height / 8 + @orb_offset_y, 1, 0.75, 0.75, Gosu::Color::rgb(135, 135, 135))
  end
  def update
    @orb_num1 += @change
    @orb_offset_y += @change * @orb_num
    if @orb_num1 >= 10
      @orb_num1 = 0
      @orb_num *= -1
    end
  end
end
