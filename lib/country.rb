require 'ostruct'

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
    $countries.values.sort { |a,b| (b['normalised']['__average__'] || 0) <=> (a['belgiums']['__average__'] || 0) }.
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
    end.map { |c| Country.new(c) }.
        sort { |a,b| b.normalised['__average__'].to_f <=> a.normalised['__average__'].to_f }
  end

  def self.find_by_category(category)
    $countries.values.select do |country|
      next unless country['normalised']
      country['normalised'].include? category
    end.
      map { |c| Country.new(c) }.
      sort { |a,b| b.normalised[category].to_f <=> a.normalised[category].to_f }
  end

  def ad_keywords
    keywords = [slug] + wordle_summary.sort { |a,b| b[1] <=> a[1] }.map { |w| w[0] }
    keywords.uniq[0,5].join(';')
  end

  def commodities
    lookup = {}
    $commodities_by_country[lookup[name] || name]
  end

  def name
    info['country']['name']
  end

  def wikipedia
    return @wikipedia if @wikipedia
    url = "http://dbpedialite.org/search.json?term=#{URI.escape(name)}"
    results = JSON.parse(open(url).read)
    label = results.first['label'] if results.any?
    if label
      url = "http://dbpedialite.org/titles/#{URI.escape(label)}"

      xml = Nokogiri::HTML(open(url).read)
      abstract = xml.xpath('//td[@property="rdfs:comment"]').first.content
      @wikipedia = OpenStruct.new(:abstract => abstract,
        :url => "http://en.wikipedia.org/wiki/#{label}")
    else
      nil
    end
  end

  def woeid
    return @woeid if @woeid
    embassy = info['country']['embassies'].first
    return nil if embassy.nil?
    position = [embassy['lat'], embassy['long']].join(',')
    url = "http://where.yahooapis.com/geocode?q=#{position}&gflags=R"
    xml = Nokogiri::HTML(open(url).read)
    @woeid = xml.xpath('//result/woeid').first.content
  end

  def weather
    return @weather if @weather
    return nil if woeid.nil?
    client = YahooWeather::Client.new
    response = client.lookup_by_woeid(woeid, YahooWeather::Units::CELSIUS)
    @weather = response
    rescue => e
      puts "Error getting weather: #{e}"
      nil
  end

  def poster_image
    @poster_image ||= PosterImage.find_by_tag(name)
  end
end
