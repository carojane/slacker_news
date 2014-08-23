require 'sinatra'
require 'redis'
require 'json'
require 'pry'

##############
####METHODS###
##############

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

########## data

def read_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  article_data = []
  serialized_articles.each do |article|
    article_data << JSON.parse(article, symbolize_names: true)
  end

  article_data
end

def write_articles(id, datetime, title, url)
  article = { id: id, datetime: datetime, title: title, url: url}

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

########## random key

def random_key
  char = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

  key = ""
  10.times { key << char[rand(char.size)]}
  key
end

########## validate url

def valid_url(url)
  url =~ /(^$)|(^((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
end

########## removes http:// from url

def remove_http(array)
  array.each do |row|
    row[:url] = row[:url].gsub(/(http\:\/\/)|(https\:\/\/)/, "")
  end
  array
end

########## checks if url is in database

def check_for_url(url)
  array = read_articles

  if array.each {|article| article[:url] == url}
    false
  else
    true
  end
end

###############
###############
###############

get '/' do
  @article_data = read_articles
  @article_data = remove_http(@article_data)

  erb :index
end

get '/submit' do
  @error_message = []

  erb :submit
end

############# submission page

post '/submit' do
  title = params["title"]
  url = params["url"]
  datetime = Time.now
  id = random_key

  @error_message = []

  if valid_url(url) && check_for_url(url) && title != ""
    write_articles(id, datetime, title, url)

    redirect '/'
  else
    @error_message << title
    @error_message << url
    @error_message << 'Please enter a valid title and url'

    unless valid_url(url)
      @error_message << 'Format of url is invalid'
    end

    unless check_for_url(url)
      @error_message << 'That article is already listed'
    end

    erb :submit
  end
end


