require "sinatra"
require "tab_parser"

set :root, File.dirname(__FILE__)

get '/' do
  File.read(File.join('public', 'index.html'))
end

post '/' do
  TabParser.parse(params[:tab])
end
