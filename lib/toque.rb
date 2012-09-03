require "toque/version"
require 'json'

require 'tmpdir'
require 'fileutils'

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

  attr_reader :tmpdir

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

  # register a cookbook with Toque
  # all registered cookbooks will be uploaded to the server together
  # you can pass :default to this if you want to upload the built-in cookbooks
  def add_cookbook(cookbook_path)
    if cookbook_path == :default
      add_cookbook default_cookbook_path
      return
    end

    # make sure the cookbook directory exists when trying to add it
    raise "Cookbook directory not found: #{ cookbook_path }" unless File.exists?(cookbook_path)

    # don't allow duplicate cookbook names
    raise "Cookbook with duplicate name added: #{ cookbook_path }" if cookbook_exists?(cookbook_path)

    @cookbooks << cookbook_path
  end

  # returns whether the given cookbook path exists
  # this is used to ensure that cookbooks with duplicate basenames aren't added
  def cookbook_exists?(cookbook_path)
    cb_name = File.basename(cookbook_path)

    @cookbooks.each do |c|
      return true if File.basename(c) == cb_name
    end

    false
  end

  # copy the builtin cookbooks to the supplied path
  # this is useful if you want to modify the existing cookbook/recipes
  # the capistrano recipe should not add_cookbook :default in this case.
  def copy_builtin_cookbooks(cookbook_path)
    raise "Cookbook directory already exists: #{ cookbook_path }" if File.exists?(cookbook_path) or !File.directory?(File.dirname(cookbook_path))

    FileUtils.cp_r default_cookbook_path, cookbook_path
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

  # returns the path to the builtin cookbooks
  def default_cookbook_path
    File.expand_path( File.join( File.dirname(__FILE__), '../cookbooks' ) )
  end

  # gathers all registered cookbooks into a new temp directory
  def build_cookbooks
    raise "No cookbooks have been registered" if cookbooks.count == 0
    @tmpdir ||= Dir.mktmpdir('toque_cookbooks')

    self.cookbooks.each do |cb|
      FileUtils.cp_r cb, @tmpdir
    end

    @tmpdir
  end

  # delete the temp cookbook directory created by Toque#build_cookbooks
  def clean_up
    return if tmpdir.nil?
    return unless File.exists?(tmpdir)

    FileUtils.rm_rf tmpdir
  end

end
