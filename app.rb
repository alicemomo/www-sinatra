require 'bundler'
Bundler.require

require 'sinatra/asset_pipeline'
require 'sinatra/content_for'
require 'yaml'

require_relative 'lib/deep_symbolize'

def load(name)
  hash = YAML::load_file(File.join(__dir__, "data/#{name}.yml"))
  hash.extend DeepSymbolizable
  hash.deep_symbolize { |key| key }
end

CITIES = load(:cities)
SESSIONS = load(:sessions)

Post = Struct.new(:content, :metadata)
JEKYLL_HEADER_PATTERN = /---(.*)---/m

class App < Sinatra::Base
  register Sinatra::AssetPipeline
  helpers Sinatra::ContentFor

  configure :development do
    require 'better_errors'
    register Sinatra::Reloader
    use BetterErrors::Middleware
  end

  get '/' do
    erb :index
  end

  get '/staff' do
    erb :staff
  end

  get '/alumni' do
    erb :alumni
  end

  get '/premiere' do
    redirect to('/programme')
  end

  get '/programme' do
    erb :programme
  end

  get '/partenaires' do
    erb :partenaires
  end

  get '/contact' do
    erb :contact
  end

  get '/postuler' do
    erb :postulate
  end

  get '/faq' do
    erb :faq
  end

  get '/blog' do
    @posts = Dir["#{File.dirname(__FILE__)}/posts/*.md"].reverse.map do |file|
      parse_post(file)
    end
    erb :blog
  end

  CITIES.each do |slug, city|
    get "/#{slug}" do
      @city = city
      erb :city
    end
  end

  private

  def parse_post(file)
    renderer = Redcarpet::Render::HTML.new
    markdown = Redcarpet::Markdown.new(renderer, extensions = {})

    file_content = File.read(file)
    yaml_content = JEKYLL_HEADER_PATTERN.match(file_content).captures[0]
    markdown_content = markdown.render(file_content.gsub(JEKYLL_HEADER_PATTERN, ''))
    Post.new(markdown_content, yaml_content ? YAML.load(yaml_content) : {})
  end
end
