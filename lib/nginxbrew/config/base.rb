module Nginxbrew

    class << self
        attr_accessor :config
    end

    def self.configure
        yield config
    end

    class Configuration
        NGX_URL = "http://nginx.org/download"
        OPENRESTY_URL = "http://openresty.org/download"

        attr_accessor :ngx_configure, :ngx_conf_path, :ngx_prefix
        attr_reader :ngx_user, :ngx_group, :nginx_log_dir,
            :builtfile, :dist_to, :tarball, :src, :url, :home_dir, :ngx_sbin_path

        def initialize(opts={})
            @home_dir = opts[:home_dir]
            @dist_dir = opts[:dist_dir]
            @ngx_version = opts[:ngx_version]
            @is_openresty = opts[:is_openresty]
            @ngx_user = opts[:ngx_user]
            @ngx_group = opts[:ngx_group]
            @version_name = version_name(@ngx_version, @is_openresty)
            @dist_to = File.join(@dist_dir, "ngx-#{@version_name}")
            @nginx_log_dir = File.join(@home_dir, "logs", @version_name)
            @src = src_name(@ngx_version, @is_openresty)
            @tarball = "#{@src}.tar.gz"
            @url = "#{@is_openresty ? OPENRESTY_URL : NGX_URL}/#{@tarball}"
            @ngx_sbin_path = File.join(@dist_to, "bin/nginx")
            @builtfile = File.join(@dist_to, "built")
            @ngx_configure = nil
            @ngx_conf_path = File.join(@dist_to, "nginx.conf")
            @ngx_prefix = File.join(@dist_to, "user/share")
        end

        def configure_command
            return @ngx_configure if @ngx_configure
            cmd =<<-EOF
                ./configure \
                --user=#{@ngx_user} \
                --group=#{@ngx_group} \
                --prefix=#{@ngx_prefix} \
                --sbin-path=#{@ngx_sbin_path} \
                --conf-path=#{@ngx_conf_path} \
                --error-log-path=#{@nginx_log_dir}/error.log \
                --http-log-path=#{@nginx_log_dir}/access.log \
                --http-client-body-temp-path=#{@home_dir}/tmp/client_body \
                --http-proxy-temp-path=#{@home_dir}/tmp/proxy \
                --http-fastcgi-temp-path=#{@home_dir}/tmp/fastcgi \
                --http-uwsgi-temp-path=#{@home_dir}/tmp/uwsgi \
                --pid-path=#{@home_dir}/run/nginx.pid
            EOF
            cmd.split(" ").join(" ")
        end

        private

        def version_name(v, is_openresty)
            is_openresty ? "openresty-#{v}" : v
        end

        def src_name(v, is_openresty)
            is_openresty ? "ngx_openresty-#{v}" : "nginx-#{v}"
        end

    end

end

