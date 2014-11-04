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

        attr_accessor :ngx_configure, :ngx_conf_path, :ngx_prefix, :ngx_user, :ngx_group

        attr_reader :ngx_user, :ngx_group, :nginx_log_dir, :ngx_sbin_path, :package_name,
            :builtfile, :dist_to, :tarball, :src, :url, :home_dir, :dist_dir, :is_openresty, :ngx_version

        def initialize(opts={})
            @home_dir = opts[:home_dir]
            @dist_dir = opts[:dist_dir]
            @ngx_version = opts[:ngx_version]
            @is_openresty = opts[:is_openresty]
            @package_name = opts[:package_name]
            @dist_to = File.join(@dist_dir, @package_name)
            @nginx_log_dir = File.join(@home_dir, "logs", @package_name)
            @src = src_name(@ngx_version, @is_openresty)
            @tarball = "#{@src}.tar.gz"
            @url = "#{@is_openresty ? OPENRESTY_URL : NGX_URL}/#{@tarball}"
            @ngx_sbin_path = File.join(@dist_to, "bin/nginx")
            @builtfile = File.join(@dist_to, "built")
            @ngx_conf_path = File.join(@dist_to, "nginx.conf")
            @ngx_configure = {}
            @ngx_prefix = @dist_to
            @ngx_user = "nginx"
            @ngx_group = "nginx"
        end

        def configure_command
            dest = ["./configure"]
            configure_options.inject(dest) do |memo, opt|
                memo << "#{opt[0]}" + (opt[1].nil? ? "" : "=#{opt[1]}")
                memo
            end.join(" ")
        end

        def configure_options
            cmd =<<-EOF
                --user=#{@ngx_user} \
                --group=#{@ngx_group} \
                --prefix=#{@ngx_prefix} \
                --sbin-path=#{@ngx_sbin_path} \
                --conf-path=#{@ngx_conf_path} \
                --error-log-path=#{@nginx_log_dir}/error.log \
                --http-log-path=#{@nginx_log_dir}/access.log \
                --http-client-body-temp-path=#{@home_dir}/tmp/client_body \
                --http-proxy-temp-path=#{@home_dir}/tmp/proxy \
                --pid-path=#{@home_dir}/run/nginx.pid
            EOF
            dest = cmd.split(" ").inject({}) do |memo, opt|
                kv = opt.split("=")
                memo[kv[0]] = (kv.size == 2) ? kv[1] : nil
                memo
            end
            dest.merge!(@ngx_configure) if @ngx_configure
            dest
        end

        private

        def src_name(v, is_openresty)
            is_openresty ? "ngx_openresty-#{v}" : "nginx-#{v}"
        end

    end

end

