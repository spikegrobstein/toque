require 'capistrano'

require File.dirname(__FILE__) + '/../lib/toque/capistrano'

describe Capistrano::Toque do
  let (:config) { Capistrano::Configuration.new }

  context "toque:run_recipes" do

    it "should set the user to the admin user"

    it "should upload the cookbooks"

    it "should initialize Toque with variables"

    it "should run chef-solo for each recipe"

    context "cleaning up cookbooks" do

      it "should clean up cookbooks"

      it "should not clean up cookbooks if :toque_no_cleanup is set"

    end

    it "should set :user back to the old value"

  end

  context "toque:upload_cookbooks" do

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

        it "should call toque:cleanup_cookbooks"

        it "should set @cleaned_up to true"

      end

      it "should write solo.rb"

    end

  end

  context "toque:cleanup_cookbooks" do

    it "should clean up the cookbooks directory"

  end

  context "when chef_server is enabled" do

    it "should define a chef_client task"

    context "toque:chef_client" do

      it "should run chef-client"

    end
  end

  context "toque:init" do

    context "toque:init:cookbooks" do

      it "should copy the gem's cookbooks directory to the local app directory"

    end

  end
end
