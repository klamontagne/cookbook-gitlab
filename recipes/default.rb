#
# Cookbook Name:: gitlab
# Recipe:: default
#
# Copyright 2012, Gerald L. Hevener Jr., M.S.
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Include cookbook dependencies
%w{ build-essential gitlab::gitlab-shell
    readline sudo openssh xml zlib python::package python::pip
    redisio::install redisio::enable }.each do |requirement|
  include_recipe requirement
end

case node['platform_family']
when "rhel"
  include_recipe "yumrepo::epel"
end

# symlink redis-cli into /usr/bin (needed for gitlab hooks to work)
link "/usr/bin/redis-cli" do
  to "/usr/local/bin/redis-cli"
end

# Install required packages for Gitlab
node['gitlab']['packages'].each do |pkg|
  package pkg
end

# Install sshkey gem into chef
chef_gem "sshkey" do
  action :install
end


# Install pygments from pip
python_pip "pygments" do
  action :install
end

# Add the gitlab user
user node['gitlab']['user'] do
  comment "Gitlab User"
  home node['gitlab']['home']
  shell "/bin/bash"
  supports :manage_home => true
end

# Fix home permissions for nginx
directory node['gitlab']['home'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0755
end

# Add the gitlab user to the "git" group
group node['gitlab']['git_group'] do
  members node['gitlab']['user']
end

# setup rbenv (after git user setup)
%w{ ruby_build rbenv::user_install }.each do |requirement|
  include_recipe requirement
end

# Install appropriate Ruby with rbenv
rbenv_ruby node['gitlab']['install_ruby'] do
  action :install
  user node['gitlab']['user']
end

# Set as the rbenv default ruby
rbenv_global node['gitlab']['install_ruby'] do
  user node['gitlab']['user']
end

# Install required Ruby Gems for Gitlab (via rbenv)
%w{ charlock_holmes bundler }.each do |gempkg|
  rbenv_gem gempkg do
    action :install
    user node['gitlab']['user']
    rbenv_version node['gitlab']['install_ruby']
  end
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['home']}/.ssh" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0700
end

# Generate and deploy ssh public/private keys
Gem.clear_paths
require 'sshkey'
gitlab_sshkey = SSHKey.generate(:type => 'RSA', :comment => "#{node['gitlab']['user']}@#{node['fqdn']}")
node.set_unless['gitlab']['public_key'] = gitlab_sshkey.ssh_public_key

# Save public_key to node, unless it is already set.
ruby_block "save node data" do
  block do
    node.save
  end
  not_if { Chef::Config[:solo] }
  action :create
end

# Render private key template
template "#{node['gitlab']['home']}/.ssh/id_rsa" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  variables(
    :private_key => gitlab_sshkey.private_key
  )
  mode 0600
  not_if { File.exists?("#{node['gitlab']['home']}/.ssh/id_rsa") }
end

# Render public key template for gitlab user
template "#{node['gitlab']['home']}/.ssh/id_rsa.pub" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :public_key => node['gitlab']['public_key']
  )
  not_if { File.exists?("#{node['gitlab']['home']}/.ssh/id_rsa.pub") }
end

# Configure gitlab user to auto-accept localhost SSH keys
template "#{node['gitlab']['home']}/.ssh/config" do
  source "ssh_config.erb"
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :trust_local_sshkeys => node['gitlab']['trust_local_sshkeys']
  )
end

# Setup gitlab-shell
execute "setup-gitlab-shell" do
  command "su - #{node['gitlab']['git_user']} -c 'cd gitlab-shell && ./bin/install'"
  user "root"
  cwd node['gitlab']['git_home']
  not_if "grep -q '#{node['gitlab']['user']}' #{node['gitlab']['git_home']}/.ssh/authorized_keys"
end

# Clone Gitlab repo from github
git node['gitlab']['app_home'] do
  repository node['gitlab']['gitlab_url']
  reference node['gitlab']['gitlab_branch']
  action :checkout
  user node['gitlab']['user']
  group node['gitlab']['group']
end

directory "#{node['gitlab']['app_home']}/tmp" do
  user node['gitlab']['user']
  group node['gitlab']['group']
  mode "0755"
  action :create
end

# Render gitlab config file
template "#{node['gitlab']['app_home']}/config/gitlab.yml" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :fqdn => node['fqdn'],
    :https_boolean => node['gitlab']['https'],
    :git_user => node['gitlab']['git_user'],
    :git_home => node['gitlab']['git_home'],
    :backup_path => node['gitlab']['backup_path'],
    :backup_keep_time => node['gitlab']['backup_keep_time'],
    :enable_omniauth => node['gitlab']['omniauth']['enable_omniauth'],
    :allow_single_sign_on => node['gitlab']['omniauth']['allow_single_sign_on'],
    :block_auto_created_users => node['gitlab']['omniauth']['block_auto_created_users'],
    :providers => node['gitlab']['omniauth']['providers']
  )
end

without_group = node['gitlab']['database']['type'] == 'mysql' ? 'postgres' : 'mysql'

# Install Gems with bundle install
execute "gitlab-bundle-install" do
  command "bundle install --without development test #{without_group} --deployment"
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  environment({ 'LANG' => "en_US.UTF-8", 'LC_ALL' => "en_US.UTF-8" })
  not_if { File.exists?("#{node['gitlab']['app_home']}/vendor/bundle") }
end

# Create tmp dirs
execute "gitlab-create-tmp" do
  command "bundle exec rake tmp:create"
  environment ({'RAILS_ENV' => 'production'})
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.directory?("#{node['gitlab']['app_home']}/tmp/sockets") and File.directory?("#{node['gitlab']['app_home']}/tmp/pids") }
end

# Create the uploads directory
directory "#{node['gitlab']['app_home']}/public/uploads" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 00755
  action :create
end

# Setup the database
case node['gitlab']['database']['type']
when 'mysql'
  include_recipe 'gitlab::mysql'
when 'postgres'
  include_recipe 'gitlab::postgres'
else
  Chef::Log.error "#{node['gitlab']['database']['type']} is not a valid type. Please use 'mysql' or 'postgres'!"
end

# Create the backup directory
directory node['gitlab']['backup_path'] do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 00755
  action :create
end

# Write the database.yml
template "#{node['gitlab']['app_home']}/config/database.yml" do
  source 'database.yml.erb'
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode '0644'
  variables(
    :adapter  => node['gitlab']['database']['adapter'],
    :encoding => node['gitlab']['database']['encoding'],
    :host     => node['gitlab']['database']['host'],
    :database => node['gitlab']['database']['database'],
    :pool     => node['gitlab']['database']['pool'],
    :username => node['gitlab']['database']['username'],
    :password => node['gitlab']['database']['password']
  )
end

# Setup database for Gitlab
execute "gitlab-bundle-rake" do
  command "bundle exec rake gitlab:setup && touch .gitlab-setup"
  environment ({'RAILS_ENV' => 'production', 'force' => 'yes'})
  cwd node['gitlab']['app_home']
  user node['gitlab']['user']
  group node['gitlab']['group']
  not_if { File.exists?("#{node['gitlab']['app_home']}/.gitlab-setup") }
end

# Render puma template
template "#{node['gitlab']['app_home']}/config/puma.rb" do
  owner node['gitlab']['user']
  group node['gitlab']['group']
  mode 0644
  variables(
    :gitlab_app_home => node['gitlab']['app_home'],
    :workers => node['gitlab']['puma_wokers']
  )
end

# Render GitLab (puma) init script
template "/etc/init.d/gitlab" do
  owner "root"
  group "root"
  mode 0755
  source "gitlab.init.erb"
  variables(
    :user => node['gitlab']['git_user'],
    :gitlab_app_home => node['gitlab']['app_home']
  )
end

# Start unicorn_rails and nginx service
%w{ gitlab nginx }.each do |svc|
  service svc do
    action [ :start, :enable ]
  end
end

bash "Create SSL key" do
  not_if { ! node['gitlab']['https'] || File.exists?(node['gitlab']['ssl_certificate_key']) }
  cwd "/etc/nginx"
  code <<-EOF
umask 077
openssl genrsa 2048 > #{node['gitlab']['ssl_certificate_key']}
EOF
end

bash "Create SSL certificate" do
  not_if { ! node['gitlab']['https'] || File.exists?(node['gitlab']['ssl_certificate']) }
  cwd "/etc/nginx"
  code "openssl req -subj \"#{node['gitlab']['ssl_req']}\" -new -x509 -nodes -sha1 -days 3650 -key #{node['gitlab']['ssl_certificate_key']} > #{node['gitlab']['ssl_certificate']}"
end

# Render nginx default vhost config
template node['gitlab']['nginx_vhost'] do #TODO remove default && install gitlab.conf
  owner "root"
  group "root"
  mode 0644
  source "nginx.default.conf.erb"
  notifies :restart, "service[nginx]"
  variables(
    :fqdn => node['fqdn'],
    :gitlab_app_home => node['gitlab']['app_home'],
    :https_boolean => node['gitlab']['https'],
    :ssl_certificate => node['gitlab']['ssl_certificate'],
    :ssl_certificate_key => node['gitlab']['ssl_certificate_key']
  )
end
