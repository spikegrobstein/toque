require "toque/version"

module Toque
  
  class << self
    
    attr_reader :chef_recipes
    
    # Register a recipe to be run
    # recipe names should be namespaced (eg: toque::database)
    # options will be passed to the capistrano run() function
    def chef_recipe(recipe_name, options={})
      @chef_recipes ||= {}
      @chef_recipes[recipe_name] = options
    end

    def build_node_json(variables, run_list=nil)
      raise "Must supply capistrano variables. None given." if variables.nil?

      # variables that we will filter out before passing to recipes
      ignored_vars = [
        :source,
        :strategy,
        :logger,
        :password
      ]
  
      # build the json data
      json_data = {}
      variables.each do |k, v|
        begin
          # ignore ignored vars
          next if ignored_vars.include?(k.to_sym)
          
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
