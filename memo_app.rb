# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'securerandom'
require 'rack/session/cookie'
require 'pg'

configure do
  connection = PG.connect(dbname: 'sinatra_memo', user: 'postgres')
  connection.exec("SELECT * FROM information_schema.tables WHERE table_name = 'memos'")
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def make_id
    SecureRandom.uuid
  end

  def db_connection(&block)
    PG.connect(dbname: 'sinatra_memo', user: 'postgres', &block)
  end

  def get_memo(id)
    db_connection do |connection|
      result_memo_data = connection.exec_params('SELECT * FROM memos WHERE id = $1', [id])
      result_memo_data.map { |memo_data| memo_data.to_h.transform_keys(&:to_sym) }.find { true }
    end
  end

  def save_memo(memo)
    db_connection do |connection|
      if memo[:id].nil? || get_memo(memo[:id]).nil?
        connection.exec_params('INSERT INTO memos (id, title, text) VALUES ($1::uuid, $2, $3) ON CONFLICT (id) DO UPDATE SET title = $2, text = $3',
                               [memo[:id], memo[:title], memo[:text]])
      else
        connection.exec_params('UPDATE memos SET title = $1, text = $2 WHERE id = $3', [memo[:title], memo[:text], memo[:id]])
      end
    end
  end
end

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @memos = db_connection do |connection|
    result_memo_data = connection.exec('SELECT * FROM memos')
    result_memo_data.map { |data| data.transform_keys(&:to_sym) }
  end
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
    id: make_id.to_sym,
    title: params[:title],
    text: params[:text]
  }
  save_memo(memo)
  redirect to("/memos/#{memo[:id]}")
end

patch '/memos/:id' do
  memo = {
    id: params[:id],
    title: params[:title],
    text: params[:text]
  }
  save_memo(memo)
  redirect to("/memos/#{memo[:id]}")
end

delete '/memos/:id' do
  db_connection { |connection| connection.exec_params('DELETE FROM memos WHERE id = $1', [params[:id]]) }
  redirect to('/memos')
end

not_found do
  erb :not_found_error
end
