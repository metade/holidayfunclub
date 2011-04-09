require 'sinatra'
require 'ostruct'
require 'json'
require 'activesupport'

$countries = JSON.parse(open('test.json').read) 

def conditions_mentioning_country(country)
  endpoint = 'http://localhost:8080/sparql/'
  
  p "   #{country}"
  query = %[
    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

    SELECT ?conditions WHERE {
      ?conditions rdf:type <http://data.linkedgov.org/data/hmrc/tariff/conditions> .
      ?conditions <http://data.linkedgov.org/syntax/hmrc/tariff/syntax#for> "Sudan" .
    } 
  ]
  response = RestClient.post(endpoint, :query => query)
  xml = Nokogiri::XML(response.to_str)
  xml.xpath('//sparql:result', 'sparql' => 'http://www.w3.org/2005/sparql-results#').count
end

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
