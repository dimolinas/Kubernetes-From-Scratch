# app.rb
require "sinatra"
set :bind, "0.0.0.0"

get "*" do
  "[v4] Hello, Kubernetes, from #{`hostname`.strip}!\n"
end