require "bundler/setup"
require "sinatra"
require_relative "lib/player"

def format_song(path)
  path.split("/").last(3).join("/").gsub(/\.[^.]+$/, "")
end

player = Player.new(volume: ENV["WEBDJ_VOLUME"].to_f || 1)
player.start_player_thread

root = "/Users/charlie/Music/iTunes/iTunes Media/Music"

before do
  @hostname = Socket.gethostname
  @player = player
end

get "/_skip" do
  @player.skip
  redirect request.referer || "/"
end

get "/*" do
  @parts = params[:splat].first.split("/")

  halt 404 if @parts.any? { |p| p.start_with?(".") }

  path = [root, *@parts].join("/")

  if Dir.exist?(path)
    @entries = Dir.entries(path).reject { |e| e.start_with?(".") }.sort_by(&:downcase)
    erb :index
  elsif File.exist?(path)
    @player.enqueue(path)
    redirect request.referer || "/"
  else
    halt 404
  end
end
