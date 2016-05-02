require 'bundler/setup'
require "pg"
require "pry"
require "sinatra/base"
require "sinatra/reloader"
require "bcrypt"

require_relative "server"

run Patchwork::Server
