require 'sinatra'
require 'csv'
require 'pry'
require 'shotgun'
require 'uri'

##############
####METHODS###
##############

def remove_http(array)
  array.each do |row|
    row[:url] = row[:url].gsub(/(http\:\/\/)|(https\:\/\/)/, "")
  end
  array
end

def read_articles
  article_data = []
  CSV.foreach("articles.csv", headers: true, header_converters: :symbol) do |row|
    article_data << row.to_hash
  end
  article_data
end

def random_key
  char = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a

  key = ""
  10.times { key << char[rand(char.size)]}
  key
end

def valid_url(url)
  url =~ /(^$)|(^((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
end

def check_for_url(url, file)
array = []
  CSV.foreach(file, headers: true, header_converters: :symbol) do |row|
    array << row[:url]
  end

  if array.include?(url)
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


post '/submit' do
  title = params["title"]
  url = params["url"]
  datetime = Time.now
  id = random_key

  @error_message = []

  if valid_url(url) && check_for_url(url, 'articles.csv') && title != ""
    CSV.open("articles.csv", "a", headers: true) do |row|
      row << [id, datetime, title, url]
    end

    redirect '/'
  else
    @error_message << title
    @error_message << url
    @error_message << 'Please enter a valid title and url'

    unless valid_url(url)
      @error_message << 'Format of url is invalid'
    end

    unless check_for_url(url, "articles.csv")
      @error_message << 'That article is already listed'
    end

    erb :submit
  end
end


