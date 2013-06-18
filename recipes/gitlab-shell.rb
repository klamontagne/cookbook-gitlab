#
# Cookbook Name:: gitolite
# Recipe:: default
#
# Copyright 2010, RailsAnt, Inc.
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
#

include_recipe "git"

# Add git user
# Password isn't set correctly in original recipe, and really no reason to set one.
user node['gitlab']['git_user'] do
  comment "Git User" 
  home node['gitlab']['git_home']
  shell "/bin/bash" 
  supports :manage_home => false
end

directory node['gitlab']['git_home'] do
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0750
end

directory "#{node['gitlab']['git_home']}/gitlab-shell" do
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0775
end

# Create a $HOME/.ssh folder
directory "#{node['gitlab']['git_home']}/.ssh" do
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0700
end

# Clone gitlab-shell repo from github
git node['gitlab']['gitlab-shell_home'] do
  repository node['gitlab']['gitlab-shell_url']
  reference node['gitlab']['gitlab-shell_branch']
  user node['gitlab']['git_user']
  group node['gitlab']['git_group']
  action :checkout
end

# config.yml template
template "#{node['gitlab']['git_home']}/gitlab-shell/config.yml" do
  source "gitlab-shell-config.erb"
  owner node['gitlab']['git_user']
  group node['gitlab']['git_group']
  mode 0644
end
