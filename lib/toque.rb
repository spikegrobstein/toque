require "toque/version"
require 'json'

module Toque
  
  # variables that we will filter out before passing to recipes
  IGNORED_CAP_VARS = [
    :source,
    :strategy,
    :logger,
    :password
  ]
  
  class << self
    
    attr_reader :recipes
    
    # Register a recipe to be run
    # recipe names should be namespaced (eg: toque::database)
    # options will be passed to the capistrano run() function
    def recipe(recipe_name, options={})
      @recipes ||= {}
      
      # if recipe_name is a symbol
      # it's implicitely a toque recipe, so prefix that shit
      if recipe_name.class == Symbol
        recipe_name = "toque::#{recipe_name}"
      end
      
      @recipes[recipe_name] = options
    end

    def build_node_json(variables, run_list=nil)
      raise "Must supply capistrano variables. None given." if variables.nil?
      
      # build the json data
      json_data = {}
      variables.each do |k, v|
        begin
          # ignore ignored vars
          next if IGNORED_CAP_VARS.include?(k.to_sym)
          
          # if the variable is callable, call it, so as to dereference it
          v = v.call if v.respond_to? :call
    
          json_data[k] = v
        rescue
          # do nothing.
        end
      end
      
      # set the run_list var unless it's nil
      unless run_list.nil?
        json_data[:run_list] = run_list
      end
  
      json_data
    end

  end
end
