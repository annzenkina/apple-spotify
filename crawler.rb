require 'nokogiri'
require 'rubygems'
require 'open-uri'
require 'net/http'

class Crawler
  def initialize(url)
    uri = URI(url)
    res = Net::HTTP.get_response(uri)
    unless res.is_a?(Net::HTTPSuccess)
      raise "not success"
    end

    @page = Nokogiri::HTML(res.body)
  end

  def parse
    playlist = Hash.new
    playlist_content = Array.new
    playlist_name = @page.css('div.page-container div.product-page-header div.album-header-metadata h1.product-name').text

    @page.css('div.page-container div.songs-list div.song').each do |el|
      track = Hash.new
      track['song'] = el.css('div.song-name-wrapper div.song-name').text
      track['artist'] = el.css('div.song-name-wrapper div.by-line a').text
      track['album'] = el.css('div.col-album a.dt-link-to').text

      # remove feat.Somebody to make it easier searching on Spotify
      track['song'] = track['song'].split(%r{\(feat\s*})[0]
      playlist_content << track
    end
    playlist['name'] = playlist_name
    playlist['content'] = playlist_content

    return playlist
  end
end
