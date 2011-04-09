
class TagCloud
  attr_accessor :klass, :wordcount
  
  def initialize(words='')
    @wordcount = count_words(words)
  end
  
  def count_words(words)
    wordcount = {}
    words.split(/\s/).each do |word| 
      word.downcase!
      if word.strip.size > 0
        unless wordcount.key?(word.strip)
          wordcount[word.strip] = 0
        else
          wordcount[word.strip] = wordcount[word.strip] + 1
        end
      end
    end
    wordcount
  end
  
  def font_ratio(wordcount={})
    min, max = 1000000, -1000000
    wordcount.each_key do |word|
      max = wordcount[word] if wordcount[word] > max
      min = wordcount[word] if wordcount[word] < min
    end
    14.0 / (max - min)
  end
  
  def build
    cloud = String.new
    ratio = font_ratio(@wordcount)
    @wordcount.each_key do |word|
      font_size = (8 + (@wordcount[word] * ratio))
      cloud << %Q{<span#{" class=\"" + klass + "_span\"" unless klass.nil? }><a href="/keywords/#{word}"#{" class=\"" + klass + "\"" unless klass.nil? } style="font-size:#{font_size}pt;">#{word}</a></span> }
    end
    cloud
  end
end