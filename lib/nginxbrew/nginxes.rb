require "net/http"
require "uri"

include Nginxbrew


module Nginxbrew

    class VersionNotFoundError < StandardError

        def initialize(v)
            super("version '#{v}' is not found in all versions of nginxes/openresties")
        end

    end

    class LocalEnv

        def initialize(dist_dir)
            @dist_dir = dist_dir
        end

        def exists?(raw_version, is_openresty)
            ret = installed_packages.detect do |v, data|
                v == raw_version && data[:openresty] == is_openresty
            end
            !ret.nil?
        end

        def installed_packages
            dest = {}
            return dest unless FileTest.directory?(@dist_dir)
            child_dirs.inject(dest) do |memo, d|
                version = NamingConvention.version_from_package(File.basename(d))
                is_openresty = NamingConvention.openresty?(version)
                raw_version = is_openresty ?
                    NamingConvention.openresty_to_raw_version(version) : version
                memo[version] = {
                    :openresty => is_openresty,
                    :raw_version => raw_version,
                    :version => version
                }
                memo
            end
        end

        def has_one_build?
            installed_packages.size == 1
        end

        private

        def child_dirs
            Pathname.new(@dist_dir).children.select{|e| e.directory? }
        end

    end

    class Nginxes

        TypeNginx = "nginx"
        TypeOpenresty = "openresty"

        attr_reader :ngx_type, :versions

        def initialize(ngx_type, versions)
            unless [TypeNginx, TypeOpenresty].include?(ngx_type)
                raise Exception.new("Invalid ngx_type #{ngx_type}")
            end
            raise Exception.new("No versions of nginx!") if versions.size == 0
            @ngx_type = ngx_type
            @versions = versions.uniq.map do |v|
                Gem::Version.new(v) # 1.15.x <> 1.8.x should be 1.15.x > 1.8.x
            end.sort.reverse.map do |v|
                v.to_s
            end
        end

        def size
            @versions.size
        end

        def filter_versions(head_of)
            src_numbers = head_of.split(".")
            src_numbers_size = src_numbers.size
            r = @versions.select do |v|
                v.split(".").slice(0, src_numbers_size) == src_numbers
            end
            raise VersionNotFoundError.new(head_of) if r.size == 0
            r
        end

        def head_of(version)
            src_numbers = version.split(".")
            src_numbers_size = src_numbers.size
            r = @versions.detect do |v|
                v.split(".").slice(0, src_numbers_size) == src_numbers
            end
            raise VersionNotFoundError.new(version) unless r
            r
        end

        def self.nginxes
            versions = html_body_of("http://nginx.org", "/download/").
                gsub(/href="nginx\-([0-9\.]+?)\.tar\.gz"/).inject([]) do |memo, match|
                    memo << $1
                    memo
            end
            Nginxes.new(TypeNginx, versions)
        end

        def self.openresties
            versions = html_body_of("http://openresty.org", "/").
                gsub(/ngx_openresty\-([0-9\.]+?)\.tar\.gz/).inject([]) do |memo, match|
                    memo << $1
                    memo
            end
            Nginxes.new(TypeOpenresty, versions)
        end

        private

        def self.html_body_of(host, page)
            url = URI.parse(host)
            res = Net::HTTP.start(url.host, url.port) {|http|
                http.get(page)
            }
            raise Exception.new("Failed get list of nginx") if res.code.to_i != 200
            res.body
        end

    end

end

