$: << File.join( File.dirname(__FILE__), '/../lib' )

require 'toque'

describe Toque do

  context "#recipe" do

    before do
      Toque::recipes.clear unless Toque::recipes.nil?
    end

    it "should add the recipe to the list of recipes" do
      recipe_name = 'some_recipe'
      recipe_options = { :roles => 'app' }
      Toque::recipe recipe_name, recipe_options

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == recipe_name
      Toque::recipes[recipe_name].should == recipe_options
    end

    it "should properly namespace symbols" do
      recipe_name = :another_recipe

      Toque::recipe recipe_name

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == "toque::#{recipe_name}"
    end

    it "should not namespace if there is no symbol" do
      recipe_name = 'another_recipe'

      Toque::recipe recipe_name

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == recipe_name
    end
  end

  context "#init_node_json" do

    it "should throw an exception if no variables are passed"

    it "should throw an exception if it can't find the cookbooks directory"

    it "should ignore all Toque::IGNORED_CAP_VARS"

    it "should call any lambdas that are passed to it"

  end

  context "#json_for_runlist" do

    it "should contain the node_json under the :cap namespace"

    it "should contain the runlist"

    it "should return parsable json"

  end

  context "#solo_config" do
    it "should contain a configuration for 'file_cache_path'"

    it "should contain a configuration for 'cookbook_path'"
  end
end
