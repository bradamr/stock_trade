require 'curses'

module CursesFormattable
  FORMATTING = { blinking: Curses::A_BLINK, bold: Curses::A_BOLD,
                 normal:   Curses::A_NORMAL, underlined: Curses::A_UNDERLINE }

  COLORS = { black: Curses::COLOR_BLACK, blue: Curses::COLOR_BLUE,
             red:   Curses::COLOR_RED, white: Curses::COLOR_WHITE }

  OPTIONS = [['B', 'Buy'], ['BM', 'Buy MAX'], ['S', 'Sell'],
             ['SM', 'Sell MAX'], ['Q', 'Quit'], ['W', 'Watch Stock'], ['U', 'Unwatch Stock']]

  def add_horizontal_space(window, space = 3)
    window.setpos(window.cury, window.curx + space)
  end

  def new_line_pos(window, x_pos = 0, times = 1)
    window.setpos(window.cury + times, x_pos)
    window.refresh
  end

  def clear_from(win, y, x, times = 1)
    times.times { win.setpos(y, x); win.clrtoeol; y += 1 }
  end

  def format_option(win, key, description)
    win.attron(color_pair(1)) { win << "[#{key}]" }
    win.attron(color_pair(3)) { win << ' - ' + description }
  end

  def set_formatting
    Curses.init_pair(1, COLORS[:white], COLORS[:blue])
    Curses.init_pair(2, COLORS[:blue], COLORS[:black])
    Curses.init_pair(3, COLORS[:white], COLORS[:black])
  end
end