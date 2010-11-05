require 'json'
require 'tab_parser'

class TabRow
  attr_reader :lines, :tab
  attr_accessor :width, :line_height, :left_margin, :top_margin, :font_size, :slur_positions

  def initialize(lines)
    @lines = lines
    @width = 1000
    @line_height = 20
    @left_margin = 2
    @top_margin = 20
    @font_size = "16"
    @svg_space_by_char = @width / @lines.inject(0) {|max, i| i.size > max ? i.size : max}
    @slur_positions = []
    @tab = {}
    parse_lines
  end
  
  def self.slurs_for(line)
    offset = 0
    slurs = []
    while (md = line.match(/(\d+[hp])+\d+/, offset))
      slur = md.offset(0)
      slur[1] = slur[1] - 1
      slurs << slur
      offset = md.offset(0)[1]
    end
    slurs
  end
  
  def self.find_bar_char_positions(line)
    i = 0
    pos = []
    while (!line.index("|", i).nil?)
      i = line.index("|", i)
      pos << i
      i = i + 1          
    end
    pos
  end

  def to_json
    @tab.to_json
  end

  # {
  #   :bar_top => 000,
  #   :bar_bottom => 000,
  #   :bar_width => 000,
  #   :staff_width => 000,
  #   :bar_x => [000, 001, 002,...],
  #   :rows => 
  #     [
  #       {
  #         :is_string => t/f,
  #         :cols => {1 => "e", 10 => "4"},
  #         :slurs => [[3,5],[10,16]] 
  #       }
  #     ]
  # }
  def parse_lines
    @tab[:bar_x] = []
    @tab[:rows] = []
    @tab[:bar_width] = 0
    @tab[:staff_width] = 0
    lines.each_with_index do |line, index|
      row_hash = {}
      @tab[:bar_x] << TabRow.find_bar_char_positions(line)
      @tab[:bar_x].flatten!

      @tab[:staff_width] = line.size if line.size > @tab[:staff_width]
      row_hash[:slurs] = TabRow.slurs_for(line)
      if TabParser.is_tab_line?(line)
        row_hash[:is_string] = true
        end_of_staff = line.rindex(/[-\|]/)
        @tab[:bar_width] = end_of_staff if end_of_staff > @tab[:bar_width]
        @tab[:bar_top] = index unless @tab[:bar_top]
        @tab[:bar_bottom] = index
      end
      row_hash[:cols] = parse_row_entities(line)
      @tab[:rows] << row_hash
    end
    @tab[:bar_x] = @tab[:bar_x].uniq.sort unless @tab[:bar_x].empty?
  end
  
  def parse_row_entities(line)
    elements = {}
    col = 0
    while line.size > 0
      if line.match(/^[\- \|\:]/)
        col = col + 1
        line = line[1..-1]
      elsif md = line.match(/^((\d+[hp])+\d+)/)
        sub_col = col
        md[1].split(/[hp]/).each do |e|
          elements[sub_col] = e
          sub_col = sub_col + e.size + 1
        end
        col = col + md[1].size
        line = line[md[1].size..-1]
      elsif md = line.match(/^(\d+)/)
        elements[col] = md[1]
        col = col + md[1].size
        line = line[md[1].size..-1]
      else
        next_col = line.index(/[\- \|\:]/)
        if next_col.nil?
          elements[col] = line
          col = col + line.size
          line = ""
        else
          str = line[0..next_col - 1]
          elements[col] = str
          col = col + next_col
          line = line[next_col..-1]
        end
      end
      
    end
    elements
  end
   
end
