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

    require 'toque/capistrano'

At this point, `cap` will have a couple of additional tasks available to it. Run the `toque:init:cookbooks` task to install the `toque` cookbook and recipes into your project. These should be added to your repository. For example:

    $ cap toque:init:cookbooks
    Installing default cookbooks...
    $ git add cookbooks
    $ git commit

Out of the box, Toque provides support for configuring deploy users, resque workers and logrotate for your application. It bases the settings on capistrano variables.

To get started with the `user` recipe, add the following to your capistrano `deploy.rb`:

    # admin_user is the user that recipes are run as and MUST have sudo
    set :admin_user, 'admin'

    # deploy_user is the name of the user that the application will be run as.
    # Defaults to the 'user' value that you may have already set.
    set :deploy_user, 'deploy'

    # register the 'toque::user' recipe with Toque
    recipe 'toque::user'

That's it! If you run the `run_recipes` task, it will execute the `user` recipe on the server:

    cap toque:run_recipes

ALL capistrano variables are visible to your chef recipes under the 'cap' namespace. This prevents collisions between cap variables and some built-in Chef attributes (eg: `domain`). For example, to access the `shared_path` Capistrano variable, you would do the following in your Chef recipe:

    node.cap[:shared_path]

`recipe` takes the same options as `run` and recipes are run in the order that they are defined in the file. For instance, you would want the `toque::logrotate` recipe only on the `app` and `resque` roles, like as follows:

    recipe 'toque::logrotate', :roles => [ :app, :resque ]

Toque comes with several built-in recipes installed under a `toque` cookbook when you run the `toque:init:cookbooks` task. Look at the recipe source to see additional variables that the recipes support and see how they work.

Toque recipes can be registered by using a symbol without the `toque` namespace. For instance, the above example can be rewritten as the following:

    recipe :logrotate, :roles => [ :app, :resque ]

# Chef Server

For those of you running Chef Server, Toque also supports running `chef-client` on your nodes with the same ease as running a regular cap task. To enable access to these, just set the `:enable_chef_server` Capistrano variable to `true` as follows:

    set :enable_chef_server, true

This will add the `toque:chef_client` task, for executing `chef-client` on your nodes. Currently, this will be run with `sudo` and simultaneously on all nodes except where `:chef_client => false` is set. For example, to prevent `chef-client` from being run on your primary database server, you could do:

    role :db, 'db001.example.com', :chef_client => false

## TODO

 * `before_recipe` and `after_recipe` hooks
 * recipe plugin system, so you can add recipes by just loading new gems
 * `chef-client` support for Chef Server infrastructures
 * optimized running of recipes (run all required recipes on a given server at the same time)
 * sequential running across servers in a role with a timeout

## Acknowledgements

Work on this was inspired by my use of Chef at [Ticket Evolution](http://www.ticketevolution.com)

## License

MIT License

## Author

Spike Grobstein   
spikegrobstein@mac.com   
http://spike.grobste.in   
https://github.com/spikegrobstein   

## Copyrights

Toque software is &copy;2012 Spike Grobstein (see above) and builds on top of [Capistrano](https://github.com/capistrano/capistrano) and uses it to orchestrate [Chef](http://www.opscode.com).
