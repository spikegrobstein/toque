require 'capistrano'
require 'awesome_print'


describe "Capistrano Toque" do
  let (:config) { Capistrano::Configuration.new }

  let(:admin_user) { 'administrator' }

  before do
    config.load do
      require File.dirname(__FILE__) + '/../lib/toque/capistrano'
    end
  end

  context "chef:run_recipes" do

    context "without defined cookbooks" do
      it "should raise an error" do
        lambda { config.find_and_execute_task('chef:run_recipes') }.should raise_error

      end
    end

    context "with defined cookbooks" do

      before do
        config.load do
          cookbook :default
        end
      end

      it "should set the user to the admin user" do
        config.set(:admin_user, admin_user)

        config.should_receive(:set).with(:user, admin_user)
        config.should_receive(:toque_check_cookbooks).and_return(true)

        t = config.find_task('chef:upload_cookbooks')
        #ap t
        t.instance_eval do
          @block.should_receive(:call).and_return(false)
        end

        #ap config.find_task('chef:upload_cookbooks')

        config.find_and_execute_task('chef:run_recipes')
      end

      it "should upload the cookbooks"

      it "should initialize Toque with variables"

      it "should run chef-solo for each recipe"

      context "cleaning up cookbooks" do

        it "should clean up cookbooks"

        it "should not clean up cookbooks if :toque_no_cleanup is set"

      end

      it "should set :user back to the old value"

    end

    context "chef:upload_cookbooks" do

      context "when locating cookbooks directory" do

        it "should raise an error if cookbooks directory does not exist"

        it "should raise an error if cookbooks directory is not a directory"

      end

      context "when uploading cookbooks" do

        it "should create the cookbooks directory"

        it "should upload the cookbooks"

        it "should try to clean up if it encounters an error"

        context "when handling an error" do

          it "should raise an error if we've already tried to clean up once"

          it "should call chef:cleanup_cookbooks"

          it "should set @cleaned_up to true"

        end

        it "should write solo.rb"

      end

    end

    context "chef:cleanup_cookbooks" do

      it "should clean up the cookbooks directory"

    end

    context "when chef_server is enabled" do

      it "should define a chef_client task"

      context "chef:chef_client" do

        it "should run chef-client"

      end
    end

    context "chef:init" do

      context "chef:init:cookbooks" do

        it "should copy the gem's cookbooks directory to the local app directory"

      end

    end
  end
end
