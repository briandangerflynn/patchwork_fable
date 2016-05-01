require 'pg'
require "pry"
require "better_errors"

module Patchwork
  class Server < Sinatra::Base
    set :method_override, true

    configure :development do
      use BetterErrors::Middleware
      BetterErrors.application_root = __dir__
    end

# shows titles of stories

    get "/" do
      @fables = conn.exec("SELECT * FROM fable;")
      erb :index
    end

# add new story

    post "/" do
      @new_story = params[:title]
      conn.exec_params("INSERT INTO fable (title, user_id) VALUES ($1, $2)", [@new_story, "1"])
      @submitted = true
      redirect to("/")
    end


# view posts making up selected story

    get "/:fable_id" do
      @id = params[:fable_id].to_i
      @fable = conn.exec("SELECT * FROM fable WHERE id = #{@id};")
      @posts = conn.exec("SELECT * FROM posts WHERE fable_id = #{@id};")

      erb :story
    end

# add new part to selected story

    post "/:fable_id" do
      @id = params[:fable_id].to_i

      @new_post = params[:message]

      conn.exec_params("INSERT INTO posts (message, user_id, fable_id) VALUES ($1, $2, $3)", [@new_post, "1", @id])

      @submitted = true

      redirect to("/#{@id}")
    end

# view selected post in selected story

    get "/:fable_id/:post_id" do
      @fable_id = params[:fable_id].to_i
      @post_id = params[:post_id].to_i

      @post = conn.exec("SELECT * FROM posts WHERE fable_id = #{@fable_id} AND id = #{@post_id}")

      @story = conn.exec("SELECT * FROM fable WHERE id = #{@fable_id}")

      erb :show

    end

# edit selected post

    put "/:fable_id/:post_id" do
      @fable_id = params[:fable_id].to_i
      @post_id = params[:post_id].to_i
      @message = params[:message]

      conn.exec_params("UPDATE posts SET message = $1 WHERE fable_id = $2 AND id = $3", [@message, @fable_id, @post_id])

      redirect to("/#{@fable_id}/#{@post_id}")
    end

# delete selected post

    delete "/:fable_id/:post_id" do
      @fable_id = params[:fable_id].to_i
      @post_id = params[:post_id].to_i



      conn.exec_params("DELETE FROM posts WHERE fable_id = $1 AND id = $2", [@fable_id, @post_id])

      redirect to("/#{@fable_id}")
    end



    # private

    def conn
        if ENV["RACK_ENV"] == "production"
            PG.connect(
                dbname: ENV["POSTGRES_DB"],
                host: ENV["POSTGRES_HOST"],
                password: ENV["POSTGRES_PASS"],
                user: ENV["POSTGRES_USER"]
             )
        else
            PG.connect(dbname: "patchwork")
        end
    end

  end
end
