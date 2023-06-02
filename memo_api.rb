# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'

helpers do
  def memo_data_json_file_path(id)
    "json/memos_#{id}.json"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def make_id
    use_id = Dir.glob('json/*.json').map { |file| JSON.parse(File.read(file))['id'] }
    new_id = SecureRandom.uuid
    new_id = SecureRandom.uuid until !use_id.include?(new_id)
    new_id
  end

  def get_memo_contents_of_id(memo_id)
    if File.file?(memo_data_json_file_path(memo_id))
      memo = JSON.parse(File.read(memo_data_json_file_path(memo_id)))
      id = memo['id']
      title = memo['title']
      text = memo['text']
      { id: id, title: title, text: text }
    else
      nil
    end
  end

  def save_memo(id, memo)
    File.open(memo_data_json_file_path(id), 'w') { |file| JSON.dump(memo, file) }
  end
end

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @memo_data = Dir.glob('json/*.json').map { |file| JSON.parse(File.read(file)) }
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  memo = get_memo_contents_of_id(params[:id])
  if memo.nil?
    redirect to('not_found_error')
  else
    @id = memo[:id]
    @title = memo[:title]
    @text = memo[:text]
    erb :show
  end
end

get '/memos/:id/edit' do
  memo = get_memo_contents_of_id(params[:id])
  if memo.nil?
    redirect to('not_found_error')
  else
    @id = memo[:id]
    @title = memo[:title]
    @text = memo[:text]
    erb :edit
  end
end

post '/memos' do
  title = params[:title]
  text = params[:text]

  if title.empty? || text.empty?
    redirect to('/memos/new')
  else
    memo_id = make_id
    memo = {
      'id' => memo_id,
      'title' => title,
      'text' => text
    }
    save_memo(memo_id, memo)
    redirect to("/memos/#{memo['id']}")
  end
end

patch '/memos/:id' do
  memo_id = params[:id]
  title = params[:title]
  text = params[:text]

  if title.empty? || text.empty?
    redirect to("/memos/#{memo_id}/edit")
  else
    memo = {
      'id' => memo_id,
      'title' => title,
      'text' => text
    }  
    save_memo(memo_id, memo)
    redirect to("/memos/#{memo_id}")
  end
end

delete '/memos/:id' do
  File.delete(memo_data_json_file_path(params[:id]))
  redirect to('/memos')
end

not_found do
  erb :not_found_error
end
