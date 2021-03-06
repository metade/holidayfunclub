class NoWww
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    if request.host =~ /^www\./
      [301, {"Cache-Control" => "public, max-age=3600", "Location" => request.url.sub("//www.", "//")}, self]
    elsif request.host =~ /heroku\.com$/
      [301, {"Cache-Control" => "public, max-age=3600", "Location" => request.url.sub(".heroku.com/", ".com/")}, self]
    else
      @app.call(env)
    end
  end
  
  def each(&block)
  end
end
