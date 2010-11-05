require "sinatra"
require "haml"
require "tab_parser"

set :root, File.dirname(__FILE__)

get '/' do
  haml :index, :format => :html5
end

post '/' do
  TabParser.parse(params[:tab])
end
