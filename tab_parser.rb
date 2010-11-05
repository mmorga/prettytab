require 'tab_row'

class TabParser
  def self.is_tab_line?(line)
    return false if line.match(/#.*#/)
    line.count('-|0123456789') > (line.size / 2)
  end
  
  def self.is_chord_line?(line)
    line.match(/[\dX]{5,7}/)
  end
  
  def self.is_chord_progression_line?(line)
    !is_tab_line?(line) && (line.count("ABCDEFG \t|") > (line.size / 2))
  end
  
  def self.is_chord_lyrics_line?(line)
    !is_tab_line?(line) && !line.match(/\([A-Ga-g]\)/).nil?
  end
  
  def self.is_comment_line?(line)
    line.match(/^#.*#\s*$/) || line.strip == "#"
  end
  
  def self.draw_tabs(tab_data)
    js = <<-JS
    <script type="text/javascript">  
      function drawTab(){
        var canvas;
        var staff_index = 0;
        var tabData = #{tab_data.to_json};
        var width = 1000;
        var lineHeight = 20;
        var leftMargin = 2;
        var topMargin = 20;
        var font = "12pt Arial";        
        
        tabData.forEach(function (staff) {
          var svgSpaceByChar = width / staff["staff_width"];
          var barWidth = svgSpaceByChar * staff["bar_width"];
          canvas = document.getElementById('tab_' + staff_index);  
          if (canvas.getContext) {
            var ctx = canvas.getContext('2d');
            var row_index = 0;
            staff["rows"].forEach(function (row) {
              var y = row_index * lineHeight + topMargin;
              if (row["is_string"]) {                
                ctx.beginPath();  
                ctx.strokeStyle = "#AAA";
                ctx.moveTo(leftMargin, y);  
                ctx.lineTo(leftMargin + barWidth, y);  
                ctx.stroke();
              }
              
              row["slurs"].forEach(function (slur) {
                var x1 = leftMargin + (svgSpaceByChar * slur[0]) + (svgSpaceByChar / 4);
                var x2 = leftMargin + (svgSpaceByChar * slur[1]);
                var sy = y - (lineHeight / 2) - 1;
                var cpy = sy - (lineHeight/2);
                var cp1x = x1 + ((x2-x1)/4);
                var cp2x = x2 - ((x2-x1)/4);
                ctx.strokeStyle = "#000";
                ctx.beginPath();
                ctx.moveTo(x1, sy);
                ctx.bezierCurveTo(cp1x, cpy, cp2x, cpy, x2, sy);
                ctx.stroke();
              });

              for (var col in row["cols"]) {
                var element = row["cols"][col];
                var x = leftMargin + (svgSpaceByChar * col);
                ctx.strokeStyle = "#000";
                ctx.font = font;
                ctx.textBaseline = "middle";
                ctx.fillText(element, x, y);
              };
              
              row_index++;
            });
            
            var barTop = staff["bar_top"] * lineHeight + topMargin;
            var barBottom = staff["bar_bottom"] * lineHeight + topMargin;
            ctx.beginPath();  
            staff["bar_x"].forEach(function (pos) {
              var x = pos * svgSpaceByChar + leftMargin;
              ctx.strokeStyle = "#000";
              ctx.moveTo(x, barTop);  
              ctx.lineTo(x, barBottom);  
            });
            ctx.stroke();
          }
          staff_index++; 
        });
      }
    </script>  
    JS
  end
  
  def self.parse(string)
    lines = string.split("\n")
    TabParser.process(lines)
  end
  
  def self.process(lines)
    lines = lines.collect do |line|
      line.sub(/\t/, "        ").rstrip
    end
    counter = 0
    svg_id = 1
    tab_lines = []
    tab_line_begins = nil
    html = []
    canvas_data = []
    html << <<-HEADER
    <html>
      <head>
        <title>Girly</title>
        <style type="text/css">
          .comment {
            color: #aaa;
            font-family: "Courier","Courier New",monospace;
          }
        </style>
      </head>
      <body onload="drawTab();">
    HEADER

    lines.each do |line|
      if is_tab_line?(line)
        if tab_line_begins.nil?
          if counter > 0 && is_chord_progression_line?(lines[counter - 1])
            tab_line_begins = counter - 1
            html.pop
          else
            tab_line_begins = counter
          end
        end
      elsif !tab_line_begins.nil?
        html << <<-CANVAS
        <canvas id="tab_#{canvas_data.size}" width="1020px" height="200px"></canvas><br/>
        CANVAS
        canvas_data << TabRow.new(lines[tab_line_begins..counter - 1]).tab
        tab_line_begins = nil
      elsif is_comment_line?(line)
        html << "<span class=\"comment\">#{line.strip}</span></br/>"
      else 
        html << "#{line.strip}<br/>"
      end
      counter = counter + 1
    end
    html << TabParser.draw_tabs(canvas_data)
    html << "</body></html>"
    html.join("\n")
  end
  
  def self.read(file_name)
    File.open(file_name, "r") do |infile|
      lines = infile.readlines
      html = TabParser.process(lines)

      File.open("girly.html", "w") do |html_file|
        html_file.write(html)
      end
    end  
  end
end
