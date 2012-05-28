$: << File.join( File.dirname(__FILE__), '/../lib' )

require 'toque'

describe Toque do

  context "#add_recipe" do

    before do
      Toque::recipes.clear unless Toque::recipes.nil?
    end

    it "should add the recipe to the list of recipes" do
      recipe_name = 'some_recipe'
      recipe_options = { :roles => 'app' }
      Toque::add_recipe recipe_name, recipe_options

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == recipe_name
      Toque::recipes[recipe_name].should == recipe_options
    end

    it "should properly namespace symbols" do
      recipe_name = :another_recipe

      Toque::add_recipe recipe_name

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == "toque::#{recipe_name}"
    end

    it "should not namespace if there is no symbol" do
      recipe_name = 'another_recipe'

      Toque::add_recipe recipe_name

      Toque::recipes.keys.count.should == 1
      Toque::recipes.keys.first.should == recipe_name
    end
  end

  context "#init_node_json" do

    it "should throw an exception if no variables are passed" do
      lambda { Toque::init_node_json(nil) }.should raise_error
    end

    context "ignoring cap variables" do

      it "should ignore all Toque::IGNORED_CAP_VARS" do
        vars = {
          :application => 'some_application',
          :source => 'this should be ignored',
          :strategy => 'this should be ignored',
          :logger => 'this should be ignored',
          :password => 'this should be ignored'
        }

        node_json = Toque::init_node_json(vars)

        Toque::IGNORED_CAP_VARS.each do |k|
          node_json[k].should be_nil
        end

        node_json[:application].should_not be_nil
      end

    end

    it "should call any lambdas that are passed to it" do
      callable = mock(:call => true)

      callable.should_receive(:call).and_return('asdf')
      Toque::init_node_json(:callable => callable)
    end

    it "should not call non-callable vars" do
      variable = "just a normal var"

      variable.should_receive(:respond_to?).with(:call).and_return(false)
      variable.should_not_receive(:call)

      Toque::init_node_json(:some_var => variable)
    end

  end

  context "#json_for_runlist" do
    let(:cap_variables) do
      {
        "application" => 'Toque Test App',
        "another_var" => 'some random variable',
        "cool_var" => true
      }
    end

    let(:run_list) { [ 'toque::user', 'toque::resque', 'myapp::crons' ]}

    let(:run_list_hash) { JSON.parse(Toque::json_for_runlist(run_list)) }

    before do
      Toque::init_node_json(cap_variables)
    end

    it "should return parsable json" do
      lambda { run_list_hash }.should_not raise_error
    end

    it "should contain the node_json under the :cap namespace" do
      run_list_hash['cap'].should == cap_variables
    end

    it "should contain the runlist" do
      run_list_hash['run_list'].should == run_list
    end

  end

  context "#solo_config" do
    let(:solo_config) { Toque::solo_config }

    it "should contain a configuration for 'file_cache_path'" do
      Toque::solo_config.should =~ %r{^\s*file_cache_path\s+}
    end

    it "should contain a configuration for 'cookbook_path'" do
      Toque::solo_config.should =~ %r{^\s*cookbook_path\s+}
    end
  end
end
