require 'sinatra'
require 'open-uri'
require 'json'
require 'nokogiri'
require 'active_support/inflector'
require 'yahoo-weather'

require File.join(File.dirname(__FILE__), 'lib', 'country')
require File.join(File.dirname(__FILE__), 'lib', 'tag_cloud')
require File.join(File.dirname(__FILE__), 'lib', 'poster_image')

configure do
  FlickRaw.api_key = ENV['flickr_api_key']
  $countries = JSON.parse(open('data/test.json').read)
  $commodities_by_country = JSON.parse(open('data/commodities_by_country.json').read)
  $belgiums_max = 5  #$countries.values.map { |c| c['belgiums']['__average__'].to_f || 0 }.max.ceil
end

def tag_cloud(hash)
  return if hash.nil?
  tc = TagCloud.new
  tc.wordcount = hash
  tc.build
end

get '/' do
  response['Cache-Control'] = "public, max-age=3600"
  slug = $countries.keys[(rand*$countries.keys.size).to_i]
  @poster_image = PosterImage.find_by_tag(slug)
  erb :index
end

get '/about' do
  @poster_image = PosterImage.find_by_tag('travel')
  erb :about
end

get '/about/team' do
  @poster_image = PosterImage.find(5605893782)
  erb :about_team
end

get '/explore' do
  response['Cache-Control'] = "public, max-age=3600"
  @poster_image = PosterImage.find_by_tag('explore')
  erb :explore, :layout => false
end

get '/keywords' do
  response['Cache-Control'] = "public, max-age=3600"
  @keywords = Country.keywords
  @poster_image = PosterImage.find_by_tag('words')
  erb :keywords
end

get '/keywords/:keyword' do |keyword|
  response['Cache-Control'] = "public, max-age=3600"
  @keyword = keyword
  @category = '__average__'
  @countries = Country.find_by_keyword(keyword)
  @poster_image = PosterImage.find_by_tag(keyword)
  erb :keyword
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

get '/categories/:category' do |category|
  response['Cache-Control'] = "public, max-age=3600"
  @category = category
  @countries = Country.find_by_category(category)
  @poster_image = PosterImage.find_by_tag(category)
  erb :category
end

get '/whatnottobring' do
  
end

get '/countries' do
  @category = '__average__'
  @countries = Country.find_by_category('__average__')
  @poster_image = PosterImage.find_by_tag('world map')
  erb :countries
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
