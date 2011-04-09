require 'sinatra'
require 'ostruct'
require 'json'
require 'flickraw'
require 'active_support/inflector'

configure do
  FlickRaw.api_key = ENV['flickr_api_key']
  $countries = JSON.parse(open('test.json').read)
end

class Country < OpenStruct
  def self.find_by_slug(slug)
    country = Country.new($countries[slug])
    country.name = slug.titleize
    country
  end
  
  def poster_image
    unless @poster_image
      photos = flickr.photos.search(
        :tags => name, 
        :is_commons => true, 
        # :content_type => 1,
        # :sort => 'interestingness-desc',
        :per_page => 1)
      if photos.any?
        sizes = flickr.photos.getSizes(:photo_id => photos.first.id)
        largest = sizes.sort { |a,b| b['width'].to_i <=> a['width'].to_i }.first
        p photos.first.to_hash
        @poster_image = OpenStruct.new(photos.first.to_hash)
        @poster_image.url = "http://www.flickr.com/photos/#{@poster_image.owner}/#{@poster_image.id}/"
        @poster_image.image_url = largest['source']
      else
        @poster_image = OpenStruct.new()
      end
    end
    @poster_image
  end
end

get '/countries/:country' do
  @country = Country.find_by_slug params[:country]
  erb :country
end
