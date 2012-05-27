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

    it "should not namespace if there is no symbol"
  end
end
