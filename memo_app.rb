# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'rack/session/cookie'
require 'pg'

configure do
  conn = PG.connect(dbname: 'postgres', user: 'postgres')
  result = conn.exec("SELECT * FROM information_schema.tables WHERE table_name = 'memos'")
  conn.exec('CREATE TABLE memos (id UUID PRIMARY KEY, title varchar(255), text text)') if result.values.empty?
end

helpers do
  def conn
    @conn ||= PG.connect(dbname: 'postgres', user: 'postgres')
  end

  def memo_data_json_file_path(id)
    "json/memos_#{id}.json"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def make_id
    SecureRandom.uuid
  end

  def db_connection
    yield(conn)
  ensure
    conn&.close
  end

  def get_memo(id)
    result = conn.exec_params('SELECT * FROM memos WHERE id = $1', [id])
    result[0]&.transform_keys(&:to_sym) unless result.count.zero?
  end

  def save_memo(memo)
    db_connection do |conn|
      if memo[:id].nil? || get_memo(memo[:id]).nil?
        conn.exec_params('INSERT INTO memos (id, title, text) VALUES ($1::uuid, $2, $3) ON CONFLICT (id) DO UPDATE SET title = $2, text = $3',
                         [memo[:id], memo[:title], memo[:text]])
      else
        conn.exec_params('UPDATE memos SET title = $1, text = $2 WHERE id = $3', [memo[:title], memo[:text], memo[:id]])
      end
    end
  end

  def delete_memo(id)
    db_connection do |conn|
      conn.exec_params('DELETE FROM memos WHERE id = $1', [id])
    end
  end
end

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @memos = []
  result = conn.exec('SELECT * FROM memos')
  @memos = result.map { |data| data.transform_keys(&:to_sym) }
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
  delete_memo(params[:id])
  redirect to('/memos')
end

not_found do
  erb :not_found_error
end
