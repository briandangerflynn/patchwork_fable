require 'pg'
require "pry"
# require "better_errors"


module Patchwork
  require "bcrypt"
  require "better_errors"
  class Server < Sinatra::Base
    set :method_override, true
    set :sessions, true


    configure :development do
      use BetterErrors::Middleware
      BetterErrors.application_root = __dir__
    end

    helpers do

      def login?
        if session[:username].nil?
          return false
        else
          return true
        end
      end

      def username
        return session[:username]
      end

    end

# shows signup page
    get "/signup" do
      erb :signup
    end

# allows user to create an account

    post "/signup" do
      email = params[:email]
      session[:username] = params[:username]
      password = BCrypt::Password::create(params[:password])

      user_emails = conn.exec("SELECT email FROM user_info").to_a
      print user_emails

      if user_emails.include? "#{email}"
        redirect "/signup"
        "An account already exists with this email. Please log into that account or create a new account with a different email."
      else
        conn.exec_params("INSERT INTO user_info (email, username, password) VALUES ($1, $2, $3)", [email, session[:username], password])

        redirect "/"
      end
    end

# shows login page

    get "/login" do
      erb :login
    end

# allows user to log in to an existing account

    post "/login" do
      @email = params[:email]
      @password = params[:password]

      @user = conn.exec(
        "SELECT * FROM user_info WHERE email=$1 LIMIT 1",
        [@email]
      ).first

      if @user && BCrypt::Password::new(@user["password"]) == params[:password]
        session[:username] = @user['username']
        redirect to("/")
      else
        redirect to("/login")
        "wrong email / password combination"
      end
    end

# allows users to visit their profile

    get "/profile/:name" do
      @getname = params[:name].to_s
      @name = conn.exec("SELECT * FROM user_info WHERE username = '#{@getname}'")
      @fables = conn.exec("SELECT * FROM user_info JOIN fable ON user_info.username = fable.author WHERE user_info.username = '#{@getname}';").to_a
      @posts = conn.exec("SELECT * FROM user_info JOIN posts ON user_info.username = posts.author WHERE user_info.username = '#{@getname}'").to_a
      erb :profile
    end

# allows users to log out

    get "/logout" do
      session.clear
      redirect to("/")
    end

# shows titles of stories

    get "/" do
      @fables = conn.exec("SELECT * FROM fable;")

      erb :index
    end

# add new story

    post "/" do
      @username = username
      @new_story = params[:title]
      @description = params[:description]
      @category = params[:category]
      conn.exec_params("INSERT INTO fable (title, description, author, category) VALUES ($1, $2, $3, $4)", [@new_story, @description, @username, @category])
      @submitted = true
      redirect to("/")
    end

# view fantasy fables
    get "/fantasy" do
      @fables = conn.exec("SELECT * FROM fable JOIN user_info ON fable.author = user_info.username WHERE category = 'fantasy';").to_a
      erb :fantasy
    end

# view horror fables
    get "/horror" do
      @fables = conn.exec("SELECT * FROM fable JOIN user_info ON fable.author = user_info.username WHERE category = 'horror';").to_a
      erb :horror
    end

# view comedy fables
    get "/comedy" do
      @fables = conn.exec("SELECT * FROM fable JOIN user_info ON fable.author = user_info.username WHERE category = 'comedy';").to_a
      erb :comedy
    end

# view sci-fi fables
    get "/scifi" do
      @fables = conn.exec("SELECT * FROM fable JOIN user_info ON fable.author = user_info.username WHERE category = 'scifi';").to_a
      erb :scifi
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
      @author = username
      @new_post = params[:message]

      conn.exec_params("INSERT INTO posts (message, author, fable_id) VALUES ($1, $2, $3)", [@new_post, @author, @id])

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
            @db||= PG.connect(
                dbname: ENV["POSTGRES_DB"],
                host: ENV["POSTGRES_HOST"],
                password: ENV["POSTGRES_PASS"],
                user: ENV["POSTGRES_USER"]
             )
        else
            @db||= PG.connect(dbname: "patchwork")
        end
    end

  end
end
