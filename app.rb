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
  $countries = JSON.parse(open('data/test.json').read)
  $commodities_by_country = JSON.parse(open('data/commodities_by_country.json').read)
  $belgiums_max = $countries.values.map { |c| c['belgiums']['__average__'].to_f || 0 }.max.ceil
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
  
  def self.order_by_belgiums
    $countries.values.sort { |a,b| (b['belgiums']['__average__'] || 0) <=> (a['belgiums']['__average__'] || 0) }.
      map { |c| Country.new(c.merge(:name => c['slug'].titleize)) }
  end
  
  def self.order_by_belgiums_keyword(keyword)
    $countries.values.sort { |a,b| (b['belgiums'][keyword] || 0) <=> (a['belgiums'][keyword] || 0) }.
      map { |c| Country.new(c.merge(:name => c['slug'].titleize)) }
  end
  
  def self.find_by_keyword(keyword)
    $countries.values.select do |country|
      next unless country['wordle_summary']
      country['wordle_summary'].include? keyword
    end.map { |c| Country.new(c.merge(:name => c['slug'].titleize)) }.
        sort { |a,b| a.slug <=> b.slug }
  end
  
  def ad_keywords
    keywords = [slug] + wordle_summary.sort { |a,b| b[1] <=> a[1] }.map { |w| w[0] }
    keywords[0,5].join(';')
  end
  
  def commodities
    lookup = {}
    $commodities_by_country[lookup[name] || name]
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
  return if hash.nil?
  tc = TagCloud.new
  tc.wordcount = hash
  tc.build
end

get '/' do
  response['Cache-Control'] = "public, max-age=3600"
  erb :index
end

get '/explore' do
  response['Cache-Control'] = "public, max-age=3600"
  erb :explore
end

get '/keywords' do
  response['Cache-Control'] = "public, max-age=3600"
  @keywords = Country.keywords
  erb :keywords
end

get '/by/belgiums' do
  response['Cache-Control'] = "public, max-age=3600"
  countries = Country.order_by_belgiums
  @top_belgiums = countries[0,10]
  @bottom_belgiums = countries.reverse[0,10]
  erb :belgiums
end

get '/by/belgiums/:keyword' do |keyword|
  response['Cache-Control'] = "public, max-age=3600"
  countries = Country.order_by_belgiums_keyword(keyword)
  @top_belgiums = countries[0,10]
  @bottom_belgiums = countries.reverse[0,10]
  erb :belgiums
end

get '/keywords/:keyword' do |keyword|
  response['Cache-Control'] = "public, max-age=3600"
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
  response['Cache-Control'] = "public, max-age=10"
  @country = Country.find_by_slug(country)
  @title = @country.name
  erb :country
end
