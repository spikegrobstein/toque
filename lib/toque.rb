require "toque/version"
require 'json'

class Toque

  # variables that we will filter out before passing to recipes
  IGNORED_CAP_VARS = [
    :source,
    :strategy,
    :logger,
    :password
  ]

  TMP_DIR = "/tmp/toque"
  JSON_FILENAME = "node.json"
  SOLO_CONFIG_FILENAME = "solo.rb"
  COOKBOOKS_DIR = 'cookbooks'

  CHEF_CACHE = '/var/chef-solo'


  attr_reader :recipes
  attr_reader :node_json

  attr_reader :cookbooks

  def initialize
    @recipes = {}
    @cookbooks = []
  end

  # Register a recipe to be run
  # recipe names should be namespaced (eg: toque::database)
  # options will be passed to the capistrano run() function
  def add_recipe(recipe_name, options={})
    # if recipe_name is a symbol
    # it's implicitely a toque recipe, so prefix that shit
    if recipe_name.class == Symbol
      recipe_name = "toque::#{recipe_name}"
    end

    @recipes[recipe_name] = options
  end

  def add_cookbook(cookbook_path)
    debugger
    if cookbook_path == :default
      add_cookbook default_cookbook_path
      return
    end

    raise "Cookbook directory not found: #{ cookbook_path }" unless File.exists?(cookbook_path)

    @cookbooks << cookbook_path
  end

  # initialize the node json that we're going to use
  # this is called to cache the node_json so we can modify it later
  def init_node_json(variables)
    raise "Must supply capistrano variables. None given." if variables.nil?

    # build the json data
    @node_json = {}
    variables.each do |k, v|
      begin
        # ignore ignored vars
        next if IGNORED_CAP_VARS.include?(k.to_sym)

        # if the variable is callable, call it, so as to dereference it
        v = v.call if v.respond_to? :call

        @node_json[k] = v
      rescue
        # do nothing.
      end
    end

    @node_json
  end

  def json_for_runlist(runlist)
    new_json = {}
    new_json[:cap] = @node_json.dup
    new_json[:run_list] = runlist
    new_json.to_json
  end

  # returns the content of the solo configuration as a string
  # this is used for writing solo.rb on the servers
  def solo_config
    <<-EOF
      file_cache_path '#{ Toque::CHEF_CACHE }'
      cookbook_path '#{ Toque::TMP_DIR }/#{ Toque::COOKBOOKS_DIR }'
    EOF
  end

  def default_cookbook_path
    File.expand_path( File.join( File.dirname(__FILE__), '../cookbooks' ) )
  end

end
