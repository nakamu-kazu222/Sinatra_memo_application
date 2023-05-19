# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'

helpers do
  def file_path(id)
    "json/memo_#{id}.json"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def json_filename_and_max_id
    @memo_data = []
    Dir.glob('json/*').map { |file| @memo_data << JSON.parse(File.open(file).read) }
    @max_id = @memo_data.max_by { |id| id['id'].to_i }['id']
  end

  def display_memo_contents_of_id
    memo = if File.file?(file_path(params[:id]))
             File.open(file_path(params[:id])) { |file| JSON.parse(file.read) }
           else
             redirect to('not_found_error')
           end
    @id = memo['id']
    @title = memo['title']
    @text = memo['text']
  end

  def save_memo(id, memo)
    File.open(file_path(id), 'w') { |file| JSON.dump(memo, file) }
  end
end

get '/' do
  redirect to('/memo')
end

get '/memo' do
  json_filename_and_max_id
  erb :index
end

get '/memo/new' do
  erb :new
end

get '/memo/:id' do
  display_memo_contents_of_id
  erb :show
end

get '/memo/:id/edit' do
  display_memo_contents_of_id
  erb :edit
end

post '/memo' do
  json_filename_and_max_id
  memo_id = (@max_id.to_i + 1).to_s
  memo = {
    'id' => memo_id,
    'time' => Time.now,
    'title' => params[:title],
    'text' => params[:text]
  }
  save_memo(memo_id, memo)
  redirect to("/memo/#{memo['id']}")
end

patch '/memo/:id/edit' do
  memo_id = params[:id]
  memo = {
    'id' => memo_id,
    'time' => Time.now,
    'title' => params[:title],
    'text' => params[:text]
  }
  save_memo(memo_id, memo)
  redirect to("/memo/#{params[:id]}")
end

delete '/memo/:id' do
  File.delete(file_path(params[:id]))
  redirect to('/memo')
end

not_found do
  erb :not_found_error
end
