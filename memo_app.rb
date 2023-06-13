# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'rack/session/cookie'

configure do
  enable :sessions
  use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'your_secret_key'
end

helpers do
  def memo_data_json_file_path(id)
    "json/memos_#{id}.json"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def make_id
    SecureRandom.uuid
  end

  def get_memo(id)
    memo_file_path = memo_data_json_file_path(id)
    return nil unless File.exist?(memo_file_path)
  
    memo_content = File.read(memo_file_path)
    memo = JSON.parse(memo_content, symbolize_names: true)
    { id: memo[:id], title: memo[:title], text: memo[:text] }
  end

  def save_memo(memo)
    File.open(memo_data_json_file_path(memo['id']), 'w') { |file| JSON.dump(memo, file) }
  end
end

before do
  FileUtils.mkdir_p('json') unless Dir.exist?('json')
end

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @memos = Dir.glob('json/*.json').map { |file| JSON.parse(File.read(file)) }
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @memo = get_memo(params[:id])
  if @memo.nil?
    erb :not_found_error
  else
    erb :show
  end
end

get '/memos/:id/edit' do
  @memo = get_memo(params[:id])
  if @memo.nil?
    erb :not_found_error
  else
    erb :edit
  end
end

post '/memos' do
  memo = {
    'id' => make_id,
    'title' => params[:title],
    'text' => params[:text]
  }
  save_memo(memo)
  redirect to("/memos/#{memo['id']}")
end

patch '/memos/:id' do
  memo = {
    'id' => params[:id],
    'title' => params[:title],
    'text' => params[:text]
  }
  save_memo(memo)
  redirect to("/memos/#{memo['id']}")
end

delete '/memos/:id' do
  File.delete(memo_data_json_file_path(params[:id]))
  redirect to('/memos')
end

not_found do
  erb :not_found_error
end
