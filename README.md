# Sinatra_memo_application
## 概要
Sinatra を利用したメモアプリケーションです
メモを作成、編集、削除、一覧表示ができます
メモの保存には PostgreSQL を使用します

## 事前準備
- データベースを作成する
```
CREATE DATABASE sinatra_memo;
```

- 作成したデータベースに接続する
```
\c sinatra_memo
```

- テーブルを作成する
```
CREATE TABLE memos (id UUID PRIMARY KEY, title varchar(255), text text);
```

## アプリケーションを立ち上げるための手順
- リポジトリをローカル環境にコピーする
```
git clone https://github.com/nakamu-kazu222/Sinatra_memo_application.git
```

- `Sinatra_memo_application`ディレクトリに移動する
```
cd Sinatra_memo_application
```

- リモートブランチをフェッチする
```
git fetch origin refs/pull/1/head:memo_application
```

- フェッチしたブランチに切り替える
```
git checkout memo_application
```

- bundler を使用して Gem をインストールする
```
bundle install
```

- サーバーを立ち上げる
```
bundle exec ruby memo_app.rb
```

- http://localhost:4567/memos で WEBページを開く
