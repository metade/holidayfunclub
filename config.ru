require 'app'
require ::File.expand_path('../lib/no_www',  __FILE__)
use NoWww
run Sinatra::Application
