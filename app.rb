require 'sinatra'
require 'ostruct'
require 'open-uri'
require 'json'
require 'flickraw'
require 'nokogiri'
require 'active_support/inflector'

require File.join(File.dirname(__FILE__), 'lib', 'tag_cloud')

configure do
  FlickRaw.api_key = ENV['flickr_api_key']
  $countries = JSON.parse(open('test.json').read)
end

def flickr_image(tag)
  photos = flickr.photos.search(
    :tags => tag, 
    :is_commons => true, 
    # :content_type => 1,
    # :sort => 'interestingness-desc',
    :per_page => 10)
  if photos.any?
    photo = photos[(rand*photos.size).to_i]
    sizes = flickr.photos.getSizes(:photo_id => photo.id)
    largest = sizes.sort { |a,b| b['width'].to_i <=> a['width'].to_i }.first
    poster_image = OpenStruct.new(photo.to_hash)
    poster_image.url = "http://www.flickr.com/photos/#{poster_image.owner}/#{photo.id}/"
    poster_image.image_url = largest['source']
    poster_image
  else
    nil
  end
end

class Country < OpenStruct
  def self.find_by_slug(slug)
    country = Country.new($countries[slug])
    country.name = slug.titleize
    country
  end
  
  def self.keywords
    keywords = Hash.new(0)
    $countries.each do |slug,country|
      next unless country['wordle_summary']
      country['wordle_summary'].each do |keyword,count|
        keywords[keyword] += count
      end
    end
    keywords
  end
  
  def self.find_by_keyword(keyword)
    $countries.values.select do |country|
      next unless country['wordle_summary']
      country['wordle_summary'].include? keyword
    end.map { |c| Country.new(c.merge(:name => c['slug'].titleize)) }.
        sort { |a,b| a.slug <=> b.slug }
  end
  
  def wikipedia
    return @wikipedia if @wikipedia
    url = "http://dbpedialite.org/search.json?term=#{URI.escape(name)}"
    results = JSON.parse(open(url).read)
    label = results.first['label'] if results.any?
    if label
      url = "http://dbpedialite.org/titles/#{URI.escape(label)}"
      
      xml = Nokogiri::HTML(open(url).read)
      abstract = xml.xpath('//td[@property="rdfs:comment"]/p').first.content
      @wikipedia = OpenStruct.new(:abstract => abstract,
        :url => "http://en.wikipedia.org/wiki/#{label}")
    else
      nil
    end
  end
  
  def poster_image
    @poster_image ||= flickr_image(name)
  end
end

def tag_cloud(hash)
  tc = TagCloud.new
  tc.wordcount = hash
  tc.build
end

get '/' do
  erb :index
end

get '/explore' do
  erb :explore
end

get '/keywords' do
  @keywords = Country.keywords
  erb :keywords
end

get '/keywords/:keyword' do |keyword|
  @keyword = keyword
  @countries = Country.find_by_keyword(keyword)
  @poster_image = flickr_image(keyword)
  erb :keyword
end

get '/countries/random' do
  slug = $countries.keys[(rand*$countries.keys.size).to_i]
  redirect "/countries/#{slug}"
end

get '/countries/:country' do |country|
  @country = Country.find_by_slug(country)
  erb :country
end
