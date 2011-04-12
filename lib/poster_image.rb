require 'ostruct'
require 'flickraw'

class PosterImage < OpenStruct
  def self.find(id)
    photos = [flickr.photos.getInfo(:photo_id => id)]
    select_appropriate_size(photos)
  end
  
  def self.find_by_text(text)
    photos = flickr.photos.search(
      :text => text, 
      :is_commons => true,
      :sort => 'relevance-desc', 
      :per_page => 10)
    photos = flickr.photos.search(
      :text => text, 
      :sort => 'relevance-desc', 
      :license => 4,
      :per_page => 10) unless photos.any?
    select_appropriate_size(photos)
  end
  
  def self.find_by_tag(tag)
    photos = flickr.photos.search(
      :tags => tag, 
      :is_commons => true, 
      :per_page => 10)
    photos = flickr.photos.search(
      :tags => tag, 
      :sort => 'interestingness-desc',
      :license => 4,
      :per_page => 10) unless photos.any?
    select_appropriate_size(photos)
  end
  
  protected
  def self.select_appropriate_size(photos)
    if photos.any?
      photo = photos[(rand*photos.size).to_i]
      sizes = flickr.photos.getSizes(:photo_id => photo.id)
      sizes_in_order = sizes.sort { |a,b| a['width'].to_i <=> b['width'].to_i }
      largest = sizes_in_order.detect { |s| s['width'].to_i >= 1024 }
      largest ||= sizes_in_order.last
      poster_image = OpenStruct.new(photo.to_hash)
      poster_image.url = "http://www.flickr.com/photos/#{poster_image.owner}/#{photo.id}/"
      poster_image.image_url = largest['source']
      poster_image
    else
      nil
    end
  end
end
