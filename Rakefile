require 'rubygems'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'rest-client'
require 'pp'

desc 'build list of country groups'
task :country_groups do
  COUNTRY_CODES = {
    'All third countries' => '1008',
    'All destinations - export refund' => '1009',
    'Countries of destination for export of hydrochloric acid and sulphuric acid' => '1501',
    'Countries of destination for export of methylethyl ketone, toluene, acetone and ethyl ether' => '1500',
    'Export refund Sector 8' => '9E10',
  }
  results = {}
  File.open('countries.txt').read.each_line do |line|
    code = line.strip
    id = COUNTRY_CODES[code] || code
    url = "http://online.businesslink.gov.uk/bdotg/action/tariffCountryGroup?id=#{URI.escape(id)}"
    puts url
    doc = Nokogiri::HTML(open(url))
    results[code] = doc.css('table tr').map { |tr| tr.css('td').last.content.strip }
  end
  File.open('country_groups.json', 'w') { |f| f.puts results.to_json }
end

desc 'list items possibly forbidden for each country'
task :list_commodities_per_country do
  countries = [
    'Canada',
    'Egypt',
    'Guinea',
    'Iran',
    'Ivory Coast',
    'Libya',
    'Myanmar',
    'North Korea',
    'Sudan',
    'United States of America',
    'Zimbabwe'
  ]
  results = {}
  endpoint = 'http://localhost:8080/sparql/'
  countries.each do |country|
    results[country] = []
    query = %[
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX tariff: <http://data.linkedgov.org/syntax/hmrc/tariff/syntax#>

      SELECT DISTINCT ?commodity_name, ?heading WHERE {
        ?commodity tariff:hasMeasure ?measure .
        ?commodity tariff:commodityName ?commodity_name .
        ?commodity tariff:heading ?heading .
        ?measure tariff:specificCountry "#{country}" .
      }
      ORDER BY ?heading
    ]
    response = RestClient.post(endpoint, :query => query, :content_type => :json)
    
    xml = Nokogiri::XML(response.to_str)
    xml.xpath('//sparql:result', 'sparql' => 'http://www.w3.org/2005/sparql-results#').each do |result|
      id, name = result.children[1].content, result.children[3].content
      next if results[country].detect { |r| r[:name] == name }
      results[country] << { :id => id, :name => name }
    end
  end
  File.open('data/commodities_by_country.json', 'w') { |f| f.puts results.to_json }
end
