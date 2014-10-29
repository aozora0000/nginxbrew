# Nginxbrew

Nginxbrew is a tool to install multi-version of nginx/nginxopenresty into your machine.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nginxbrew'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nginxbrew

## Quick start Guide

You can install new nginx build by specifying the version as follows

    $ nginxbrew install 1.7.6

"1.7.6" is the version of nginx.

If you need to install openresty,

    $ nginxbrew install openresty-1.7.0.1


After the command execution, ~/nginxbrew (or path which set NGINXBREW_HOME in env) will be created into your machine and nginx is installed as follows

    ~/nginxbrew/bin/nginx                           -- current sbin
    ~/nginxbrew/run/                                -- directory for pid file, be shared
    ~/nginxbrew/logs/<version>/                     -- log files
    ~/nginxbrew/versions/ngx-<version>/             -- $prefix directory of each version
    ~/nginxbrew/versions/ngx-<version>/conf/        -- nginx.conf and other configuration files
    ~/nginxbrew/versions/ngx-<version>/bin/nginx    -- nginx bin for each version


Then you can start up nginx by command which same as original nginx as follows

    $ ~/nginxbrew/bin/nginx
    $ ~/nginxbrew/bin/nginx -s reload


If you want to use this nginx for default, add new line to .bashrc like as follows.

    $ echo "export PATH=$PATH:~/nginxbrew/bin" >> ~/.bashrc
    $ source ~/.bashrc

Then there are 2 nginxes are activated in your machine, you can confirm it by the command

    $ nginxbrew list

You can switch to other version of nginx as follows

    $ nginxbrew use <version>

If you want to use openresty-1.7.0.1 from other version of nginx, you can do this as follows,

    $ nginxbrew use openresty-1.7.0.1


You can see all exsiting versions of nginxes/openresties by the following command.

    $ nginxbrew nginxes
    $ nginxbrew openresties

If you specify prefix of version, the version will be filtered. 

    $ nginxbrew nginxes 1.7
      [nginx-]1.7.6
      [nginx-]1.7.5
      [nginx-]1.7.4
       ...
      [nginx-]1.7.0


## Customize configuration

You can customize Nginxbrew behavior by changing ENV.

    NGINXBREW_HOME   # change nginxbrew root directory from ~/nginxbrew to somewhere
    NGINXBREW_USER   # linux user for nginx
    NGINXBREW_GROUP  # linux group for nginx

You can change directory/options for nginx if you write configfile for nginxbrew.

The following my_config.rb is configuration to share $prefix of nginx & nginx.conf troughout all builds of nginx.

```ruby
Nginxbrew.configure do |config|
    config.ngx_prefix = File.join(config.home_dir, "share")
    config.ngx_conf_path = File.join(config.home_dir, "share/nginx.conf")
    config.ngx_configure =<<-EOF
        # --- options for ./configure, starts from ./configure ...
    EOF
end
```


after that, specify path to config file which you wrote as follows

    $ export NGINXBREW_CONFIG=/path/to/my_config.rb


then nginxbrew starts to using this configuration.

## TODO

 - write tests completely
 - installable the same version of nginx with defferent labels like as follows

    $ nginxbrew install prj1 1.7.6

    $ nginxbrew install prj2 1.7.6

    $ nginxbrew use 1.7.6-prj1

 - multiple install

    $ nginxbrew install 1.4 openresty-1.7 1.7.5


## Contributing

1. Fork it ( https://github.com/[my-github-username]/nginxbrew/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
