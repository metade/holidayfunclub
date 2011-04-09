require 'sinatra'
require 'ostruct'
require 'json'
require 'activesupport'

$countries = JSON.parse(open('test.json').read)
class Country < OpenStruct
  def self.find_by_slug(slug)
    country = Country.new($countries[slug])
    country.name = slug.titleize
    country
  end
end

get '/countries/:country' do
  @country = Country.find_by_slug params[:country]
  erb :country
end
