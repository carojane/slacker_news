require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'pry'

##############
####METHODS###
##############

########### connection

def get_connection
  begin
    connection = PG.connect(dbname: 'slacker_news')

    yield(connection)

  ensure
    connection.close
  end
end

########## data

def read_articles
  get_connection do |conn|
    query = 'SELECT title, url, datetime FROM articles'
    conn.exec(query).to_a
  end
end

def write_articles(title, url)
  get_connection do |conn|
    statements = 'INSERT INTO articles (datetime, title, url)
      VALUES (now(), $1, $2)'
    conn.exec(statements, [title, url])
  end
end

########## validate url

def valid_url(url)
  url =~ /(^$)|(^((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
end

########## removes http:// from url

def remove_http(array)
  array.each do |row|
    row["url"] = row["url"].gsub(/(http\:\/\/)|(https\:\/\/)/, "")
  end
  array
end

########## checks if url is in database

def check_for_url(url)
  array = read_articles

  if array.any? {|article| article["url"] == url}
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

  @error_message = []

  if valid_url(url) && check_for_url(url) && title != ""
    write_articles(title, url)

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


