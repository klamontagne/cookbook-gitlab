# <a name="title"></a> cookbook-gitlab [![Build Status](https://secure.travis-ci.org/klamontagne/cookbook-gitlab5.png?branch=master)](http://travis-ci.org/atomic-penguin/cookbook-gitlab)

## Description

This cookbook will deploy gitlab; a free project and repository management
application.

Code hosted on github [here](https://github.com/gitlabhq/gitlabhq/tree/stable).

This cookbook was developed on Ubuntu 12.04.  Other platforms may need some tweaks,
please open an issue or send a pull request on GitHub

## Requirements
============

* Hard disk space
  - About 200 Mb, plus enough space for repositories on /home/git

* Nginx package
  - All platforms need an nginx package to configure Nginx and Unicorn.

## Cookbooks + Acknowledgements

The dependencies in this cookbook add up to over 1,500 lines of code.
This would not have been possible without the great community work of so many others.
Much kudos to everyone who added indirectly to the epicness of this cookbook.

* [ruby\_build](http://fnichol.github.com/chef-ruby_build/) and [rbenv](https://github.com/fnichol/chef-rbenv)
  - Thanks to Fletcher Nichol for his awesome ruby\_build cookbook.
    This ruby\_build LWRP is used to build Ruby 1.9.2 for gitlab,
    since Redhat shipped rubies are not compatible with the application.

* gitolite
  - Big thanks to Ruan David's [gitolite](http://ckbk.it/gitolite) as
    it certainly helped with the development of this cookbook.
    Unfortunately we had to implement our cookbook in such a way that
    directly conflicts with the original cookbook.

* [chef\_gem](http://ckbk.it/chef_gem)
  - Thanks to Chris Roberts for this little gem helper.  This cookbook
    provides a compatible gem resource for Omnibus on Chef versions less
    than 0.10.8

* [redisio](http://ckbk.it/redisio)
  - Thanks to Brian Bianco for this Redis cookbook, because I don't know
    anything about Redis.  Thanks to this cookbook I still don't know
    anything about Redis, and that is the best kind of cookbook.  One
    that just works out of the box.

* Opscode, Inc cookbooks
  - [git](http://ckbk.it/git)
  - [build-essential](http://ckbk.it/build-essential)
  - [python::pip](http://ckbk.it/python)
  - [sudo](http://ckbk.it/sudo)
  - [openssh](http://ckbk.it/openssh)
  - [perl](http://ckbk.it/perl)
  - [xml](http://ckbk.it/xml)
  - [zlib](http://ckbk.it/zlib)


## Notes about conflicts

* [nginx](http://ckbk.it/nginx) cookbook
  - Our default recipe templates out the /etc/nginx/conf.d/default.conf or /etc/nginx/sites-available/default.  This will directly
    conflict with another cookbook, such as nginx, or APT package management, trying to manage this file.

## Attributes

* gitlab['gitlab-shell\_url']
  - Github gitlab-shell address
  - Default https://github.com/gitlabhq/gitlab-shell.git

* gitlab['git\_user'] & gitlab['git\_group']
  - Git service account for GitLab
  - Default git

* gitlab['git\_home']
  - Top-level home for GitLab, gitlab-shell and repositories
  - Default /home/git

* gitlab['gitlab-shell\_home']
  - Application home for gitlab-shell
  - Default /home/git/gitlab-shell

* gitlab['user'] & gitlab['group']
  - Gitlab service user and group for Puma Rails app
  - Default git

* gitlab['home']
  - Gitlab top-level home for service account
  - default /home/git

* gitlab['app\_home']
  - Gitlab application home
  - Default /home/git/gitlab

* gitlab['gitlab\_url']
  - Github gitlab address
  - Default git://github.com/gitlabhq/gitlabhq.git

* gitlab['gitlab\_branch']
  - Gitlab git branch
  - Default 5-2-stable

* gitlab['packages']
  - Platform specific OS packages

* gitlab['trust\_local\_sshkeys']
  - ssh\_config key for gitlab to trust localhost keys automatically
  - Defaults to yes

* gitlab['install\_ruby']
  - Attribute to determine ruby version installed by rbenv
  - Default 1.9.3-p429

* gitlab['https']
  - Whether https should be used
  - Default false

* gitlab['ssl\_certificate'] & gitlab['ssl\_certificate\_key']
  - Location of certificate file and key if https is true.
    A self-signed certificate is generated if certificate is not present.
  - Default /etc/nginx/#{node['fqdn']}.crt and /etc/nginx/#{node['fqdn']}.key

* gitlab['ssl\_req']
  - Request subject used to generate a self-signed SSL certificate

* gitlab['backup\_path']
  - Path in file system where backups are stored.
  - Defaults to gitlab['app\_home'] + backups/

* gitlab['backup\_keep\_time']
  - In seconds. Older backups will automatically be deleted when new backup is created. Set to 0 to keep backups forever.
  - Defaults to 604800

* gitlab['puma_workers']
  - Number of puma workers for clustering mode (see puma.rb)
  - Defaults to 0 (disabled)

* gitlab['omniauth']['enable_omniauth'], gitlab['omniauth']['allow_single_sign_on'], gitlab['omniauth']['block_auto_created_users']
  - Omniauth support variables (see gitlab.yml)
  - Defaults disable Omniauth
* gitlab['omniauth']['providers']
  - Array of providers for omniauth (Google, Twitter, GitHub), you need to install the appropriate gem (as the git user) for others.
  - Example:  [ { :name => "google_oauth2", :app_id => "xyz.apps.googleusercontent.com", :app_secret => "abcd" } ]

### Database Attributes

**Note**, most of the database attributes have sane defaults. You will only need to change these configuration options if
you're using a non-standard installation. Please see `attributes/default.rb` for more information on how a dynamic attribute
is calculated.

* gitlab['database']['type']
  - The database (datastore) to use.
  - Options: "mysql", "postgres"
  - Default "mysql"

* gitlab['database']['adapter']
  - The Rails adapter to use with the database type
  - Options: "mysql2", "postgresql"
  - Default (varies based on `type`)

* gitlab['database']['encoding']
  - The database encoding
  - Default (varies based on `type`)

* gitlab['database']['host']
  - The host (fqdn) where the database exists
  - Default `localhost`

* gitlab['database']['pool']
  - The maximum number of connections to allow
  - Default 5

* gitlab['database']['database']
  - The name of the database
  - Default `gitlab`

* gitlab['database']['username']
  - The username for the database
  - Default `gitlab`

Usage
=====

Optionally override application paths using gitlab['git\_home'] and gitlab['home'].

Add recipe gitlab::default to run\_list.  Go grab a lunch, or two, if Ruby has to build.

The default admin credentials for the gitlab application are as follows:

    User: admin@local.host
    Password: 5iveL!fe

Of course you should change these first thing, once deployed.

License and Author
==================

Author: Gerald L. Hevener Jr., M.S.
Copyright: 2012

Author: Eric G. Wolfe
Copyright: 2012

Author: K. Lamontagne
Copyright: 2013

Gitlolite Author: David Ruan
Copyright: RailsAnt, Inc., 2010

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
