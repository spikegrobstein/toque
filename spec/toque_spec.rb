$: << File.join( File.dirname(__FILE__), '/../lib' )

require 'toque'

describe Toque do
  let(:toque) { Toque.new }

  context "#add_recipe" do

    before do
      toque.recipes.clear unless toque.recipes.nil?
    end

    it "should add the recipe to the list of recipes" do
      recipe_name = 'some_recipe'
      recipe_options = { :roles => 'app' }
      toque.add_recipe recipe_name, recipe_options

      toque.recipes.keys.count.should == 1
      toque.recipes.keys.first.should == recipe_name
      toque.recipes[recipe_name].should == recipe_options
    end

    it "should properly namespace symbols" do
      recipe_name = :another_recipe

      toque.add_recipe recipe_name

      toque.recipes.keys.count.should == 1
      toque.recipes.keys.first.should == "toque::#{recipe_name}"
    end

    it "should not namespace if there is no symbol" do
      recipe_name = 'another_recipe'

      toque.add_recipe recipe_name

      toque.recipes.keys.count.should == 1
      toque.recipes.keys.first.should == recipe_name
    end
  end

  context "cookbooks" do

    context "#add_cookbook" do
      let(:new_cookbook_path) { 'some_cookbook' }

      it "should add a cookbook to the @cookbooks array" do
        File.should_receive(:exists?).with(new_cookbook_path).and_return(true)
        lambda { toque.add_cookbook(new_cookbook_path) }.should change { toque.cookbooks.count }.by(1)
      end

      it "should raise an error if the added cookbook does not exist" do
        File.should_receive(:exists?).with(new_cookbook_path).and_return(false)
        lambda { toque.add_cookbook(new_cookbook_path) }.should raise_error
      end

      it "should accept :default as a symbol and add the gem's cookbooks" do
        default_cookbook_path = toque.send(:default_cookbook_path)

        File.should_receive(:exists?).with(default_cookbook_path).and_return(true)
        toque.should_receive(:default_cookbook_path).exactly(:once).and_return(default_cookbook_path)

        toque.add_cookbook :default

        toque.cookbooks.last.should == default_cookbook_path
      end

      it "should raise an error if 2 cookbooks with the same basename are added" do
        File.stub(:exists? => true)

        lambda { toque.add_cookbook 'asdf' }.should_not raise_error
        lambda { toque.add_cookbook 'qwer' }.should_not raise_error
        lambda { toque.add_cookbook 'asdf' }.should raise_error
      end

    end

    context "#build_cookbooks" do

      it "should raise an error if there are no registered cookbooks" do
        toque.stub(:cookbooks => [])

        lambda { toque.build_cookbooks }.should raise_error
      end

      it "should create a cookbooks temp directory" do
        toque.should_receive(:cookbooks).at_least(:twice).and_return(['some_cookbook'])
        Dir.should_receive(:mktmpdir).and_return('/tmp/toque_cookbook_test_dir')
        FileUtils.stub(:cp_r => true)

        toque.build_cookbooks
      end

      it "should copy the cookbooks into one cookbooks directory" do
        toque.should_receive(:cookbooks).at_least(:twice).and_return(['some_cookbook'])
        Dir.stub(:mktmpdir => true)
        FileUtils.should_receive(:cp_r)

        toque.build_cookbooks
      end

    end

    context "#copy_builtin_cookbooks" do

      it "should copy the built-in cookbooks" do
        File.stub(:exists? => false)
        File.stub(:directory? => true)
        FileUtils.should_receive(:cp_r)

        toque.copy_builtin_cookbooks('asdf')
      end

      it "should raise an error if the destination already exists" do
        File.stub(:exists? => true)
        File.stub(:directory? => true)

        lambda { toque.copy_builtin_cookbooks('asdf') }.should raise_error
      end

    end

  end

  context "#clean_up" do

    before do
      toque.stub(:tmpdir => 'asdf')
    end

    after do
      toque.clean_up
    end

    it "should delete the temp cookbooks if they exist" do
      File.stub(:exists? => true)
      FileUtils.should_receive(:rm_rf)
    end

    it "should not delete the temp cookbooks if they don't exist" do
      File.stub(:exists? => false)
      FileUtils.should_not_receive(:rm_rf)
    end

  end

  context "#init_node_json" do

    it "should throw an exception if no variables are passed" do
      lambda { toque.init_node_json(nil) }.should raise_error
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

        node_json = toque.init_node_json(vars)

        Toque::IGNORED_CAP_VARS.each do |k|
          node_json[k].should be_nil
        end

        node_json[:application].should_not be_nil
      end

    end

    it "should call any lambdas that are passed to it" do
      callable = mock(:call => true)

      callable.should_receive(:call).and_return('asdf')
      toque.init_node_json(:callable => callable)
    end

    it "should not call non-callable vars" do
      variable = "just a normal var"

      variable.should_receive(:respond_to?).with(:call).and_return(false)
      variable.should_not_receive(:call)

      toque.init_node_json(:some_var => variable)
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

    let(:run_list_hash) { JSON.parse(toque.json_for_runlist(run_list)) }

    before do
      toque.init_node_json(cap_variables)
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
    let(:solo_config) { toque.solo_config }

    it "should contain a configuration for 'file_cache_path'" do
      toque.solo_config.should =~ %r{^\s*file_cache_path\s+}
    end

    it "should contain a configuration for 'cookbook_path'" do
      toque.solo_config.should =~ %r{^\s*cookbook_path\s+}
    end
  end
end
