require 'bundler/setup'
require 'sinatra'
require 'dotenv'
require 'rspotify'
require_relative 'crawler'
require 'uri'
require 'byebug'
require 'omniauth'
require 'rspotify/oauth'

Dotenv.load

RSpotify.authenticate(ENV.fetch('SPOTIFY_PUBLIC'), ENV.fetch('SPOTIFY_PRIVATE'))

use Rack::Session::Cookie

use OmniAuth::Builder do
  provider :spotify, ENV.fetch('SPOTIFY_PUBLIC'), ENV.fetch('SPOTIFY_PRIVATE'), scope: 'user-read-private user-read-email playlist-read-collaborative playlist-modify-public playlist-read-private playlist-modify-private'
end

get "/" do
  erb :index
end

post "/convert" do
  @spotify_user = RSpotify::User.new(session[:spotify])
  @songs = Array.new

  playlist_url = params[:playlist_url]
  unless playlist_url && playlist_url.size > 0
    status 400
    return
  end

  crawler = Crawler.new(playlist_url)
  playlist = crawler.parse


  @playlist_name = playlist['name']
  @songs = find_tracks_spotify(playlist)

  # raise @songs.inspect
  erb :index
end

get '/auth/failure' do
  puts ":("
end

get '/auth/spotify/callback' do
  session[:spotify] = request.env['omniauth.auth']
  # @spotify_user = RSpotify::User.new(request.env['omniauth.auth'])

  # puts @spotify_user.inspect

  erb :index
end

post "/add_to_playlist" do

  # playlist = @spotify_user.create_playlist!('my-awesome-playlist')

end

def find_tracks_spotify(parsed_playlist)
  songs = Array.new

  parsed_playlist['content'].each do |track|
    if track['song'] != "" && track['artist'] != ""
      search_result = RSpotify::Track.search("#{track['song']} #{track['artist']}", limit: 20)


      search_result.each do |song|
        # puts("#{song.name.inspect} - #{song.album.name}- #{song.preview_url}" )
        song.artists.each do |artist|
          if artist.name == track['artist'] && song.name.strip == track['song'].strip
            sng = Hash.new
            sng['song'] = song
            sng['name'] = song.name
            sng['parsed-album'] = track['album']
            sng['preview-url'] = song.preview_url
            songs << sng
          end
        end
      end
    end
  end
  songs
end

def add_to_playlist(parsed_playlist)
  # playlist = @spotify_user.create_playlist!('my-awesome-playlist')

  parsed_playlist.each do |track|
    song = RSpotify::Track.search(track['song'] + " " + track['artist'])

    song.each do |sng|
      sng.artists.each do |artist|
        if artist.name == track['artist']
          puts("#{artist.name} - #{sng.name}")
        end
      end
    end
  end
end
