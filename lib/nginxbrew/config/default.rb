Nginxbrew.configure do |config|
    # config.ngx_prefix = File.join(config.home_dir, "share")
    # config.ngx_conf_path = File.join(config.home_dir, "conf/nginx.conf")
    # config.ngx_user = "nobody"
    # config.ngx_group = "nobody"
    # config.ngx_configure.merge!({
    #     "--with-lua51" => nil,
    #     "--pid-path" => "/tmp/nginx.pid",
    #     "--http-fastcgi-temp-path" => File.join(config.home_dir, "/tmp/fastcgi"),
    #     "--http-uwsgi-temp-path" => File.join(config.home_dir, "/tmp/uwsgi"),
    #     "--with-select_module" => nil,
    # })
end

