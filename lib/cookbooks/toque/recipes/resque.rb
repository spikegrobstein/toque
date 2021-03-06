#
# Cookbook Name:: toque
# Recipe:: resque
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# configures the resque workers
# uses the following capistrano variables:
# * resque_worker_count -- default 6
# * deploy_user
# * resque_queues -- default '*'
# * resque_queues_X -- worker-specific resque queues, any undefined ones will fall back to resque_queues setting, which defaults to '*'

@resque_worker_count = node['resque_worker_count'] || 6
@resque_queues = node['resque_queues'] || '*'
@master_config = "#{ node.application }-resque"

template_variables = {
  :shared_path => node.shared_path,
  :deploy_user => node.deploy_user,
  :master_config => @master_config,
  :queues => @resque_queues,
  :worker_count => @resque_worker_count,
  :rails_env => node[:rails_env] || 'development',
  :current_path => node.current_path
}

template "/etc/init/#{ @master_config }.conf" do
  source 'resque.conf.erb'
  mode '0644'
  
  owner 'root'
  group 'root'
  
  variables template_variables
end

1.upto @resque_worker_count do |i|
  
  vars = template_variables.dup
  
  vars[:worker_number] = i
  
  # customized queues?
  if node["resque_queues_#{i}"].nil?
    vars[:queues] = @resque_queues
  else
    vars[:queues] = node["resque_queues_#{i}"]
  end
  
  template "/etc/init/#{ node.application }-resque-#{ i }.conf" do
    source 'resque-X.conf.erb'
    
    mode '0644'

    owner 'root'
    group 'root'

    variables vars
  end
  
end