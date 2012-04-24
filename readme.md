     .__ _ __.   
    ( (  :  ) )   _____                   
     ||  |  ||   |_   _|__  __ _ _  _ ___ 
     ||  |  ||     | |/ _ \/ _` | || / -_)
     ||__|__||     |_|\___/\__, |\_,_\___|
     |||||||||                |_|  Chef, Meet Capistrano
     '"""""""'

# Summary

Use Capistrano to define variables and make them visible to your chef recipes.

Assumes that machines are ready to go for chef-solo, at the moment.

Very much a work in progress.

# Quick Start

Getting started using Toque is very easy. First, require it in your `Capfile` before you load your main `deploy.rb`:

    require 'toque'

At this point, `cap` will have a couple of additional tasks available to it. Run the `toque:init:cookbooks` task to install the `toque` cookbook and recipes into your project. These should be added to your repository. For example:

    $ cap toque:init:cookbooks
    Installing default cookbooks...
    $ git add cookbooks
    $ git commit
    
Out of the box, Toque provides support for configuring deploy users, resque workers and logrotate for your application. It bases the settings on capistrano variables.

To get started with the `user` recipe, add the following to your capistrano `deploy.rb`:

    set :admin_user, 'admin' # this should be a user that has sudo access. This is the user that recipes are run as.
    set :deploy_user, 'deploy' # this is the name of the user that the application will be run as. This defaults to the 'user' value that you may have already set.
    
    # now, tell Toque that you want to run that recipe:
    Toque::chef_recipe 'toque::user'
    
That's it! If you run the `run_recipes` task, it will execute the `user` recipe on the server:

    cap toque:run_recipes

ALL capistrano variables are visible to your chef recipes. `Toque::chef_recipe` takes the same options as `run` and recipes are run in the order that they are defined in the file.

Toque comes with several built-in recipes installed under a `toque` cookbook when you run the `toque:init:cookbooks` task. Look at the recipe source to see additional variables that the recipes support and see how they work.

## License

MIT License

## Author

Spike Grobstein   
spikegrobstein@mac.com   
http://spike.grobste.in   
https://github.com/spikegrobstein   

## Copyrights

Toque software is &copy;2012 Spike Grobstein (see above) and builds on top of [Capistrano](https://github.com/capistrano/capistrano) and uses it to orchestrate [Chef](http://www.opscode.com).