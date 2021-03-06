#
# Cookbook Name:: gitlab
# Attributes:: default
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

# Set attributes for the git user
default['gitlab']['user'] = "git"
default['gitlab']['group'] = "git"
default['gitlab']['home'] = "/home/git"
default['gitlab']['app_home'] = "#{node['gitlab']['home']}/gitlab"

# Set github URL for gitlab
default['gitlab']['gitlab_url'] = "git://github.com/gitlabhq/gitlabhq.git"
default['gitlab']['gitlab_branch'] = "5-3-stable"

# Database setup
default['gitlab']['database']['type'] = "mysql"
default['gitlab']['database']['adapter'] = default['gitlab']['database']['type'] == "mysql" ? "mysql2" : "postgresql"
default['gitlab']['database']['encoding'] = default['gitlab']['database']['type'] == "mysql" ? "utf8" : "unicode"
default['gitlab']['database']['host'] = "localhost"
default['gitlab']['database']['pool'] = 5
default['gitlab']['database']['database'] = "gitlab"
default['gitlab']['database']['username'] = "gitlab"

# nginx vhost file path
case node['platform']
when "ubuntu","debian"
  default['gitlab']['nginx_vhost'] = "/etc/nginx/sites-available/default"
else  # "redhat","centos","amazon","scientific" ## other?
  default['gitlab']['nginx_vhost'] = "/etc/nginx/conf.d/default.conf"
end

# Required packages for Gitlab
case node['platform']
when "ubuntu","debian"
  default['gitlab']['packages'] = %w{
    curl wget checkinstall libxslt-dev libsqlite3-dev
    libcurl4-openssl-dev libssl-dev libmysql++-dev
    libicu-dev libc6-dev libyaml-dev nginx python python-dev
  }
when "redhat","centos","amazon","scientific"
  case node['platform_version'].to_i
  when 5
    default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel libyaml-devel
      nginx python26 python26-devel
    }
  when 6
    default['gitlab']['packages'] = %w{
      curl wget libxslt-devel sqlite-devel openssl-devel
      mysql++-devel libicu-devel glibc-devel
      libyaml-devel nginx python python-devel
    }
  end
else
  default['gitlab']['packages'] = %w{
    curl wget checkinstall libxslt-dev libsqlite3-dev
    libcurl4-openssl-dev libssl-dev libmysql++-dev
    libicu-dev libc6-dev libyaml-dev nginx python
    python-dev
  }
end

default['gitlab']['trust_local_sshkeys'] = "yes"

default['gitlab']['install_ruby'] = "1.9.3-p429"

default['gitlab']['https'] = false
# hostname used for gitlab-shell. Set as https if you set the above to true
default['gitlab']['gitlab_api_url'] = "http://localhost/"

default['gitlab']['ssl_certificate'] = "/etc/nginx/#{node['fqdn']}.crt"
default['gitlab']['ssl_certificate_key'] = "/etc/nginx/#{node['fqdn']}.key"
default['gitlab']['ssl_req'] = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/CN=#{node['fqdn']}/emailAddress=root@localhost"


default['gitlab']['backup_path'] = "tmp/backups"
default['gitlab']['backup_keep_time'] = 604800

# workers for puma "cluster mode", see config/puma.rb
default['gitlab']['puma_wokers'] = 0

# rbenv
node.default['rbenv']['user_installs'] = [
  { 'user' => default['gitlab']['user'] }
]

# Google oauth2
default['gitlab']['omniauth']['enable_omniauth'] = false
default['gitlab']['omniauth']['allow_single_sign_on'] = false
default['gitlab']['omniauth']['block_auto_created_users'] = true
default['gitlab']['omniauth']['providers'] = {}
#example
#default['gitlab']['omniauth']['providers'] = [ { :name => "google_oauth2", 
#                                     :app_id => "xyz.apps.googleusercontent.com",
#                                     :app_secret => "abcd" } ]




