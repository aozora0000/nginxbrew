require "net/http"
require "uri"


module Nginxbrew

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
            @versions = versions.uniq.sort.reverse
        end

        def size
            @versions.size
        end

        def filter_versions(head_of)
            src_numbers = head_of.split(".")
            src_numbers_size = src_numbers.size
            @versions.select do |v|
                v.split(".").slice(0, src_numbers_size) == src_numbers
            end
        end

        def head_of(version)
            src_numbers = version.split(".")
            src_numbers_size = src_numbers.size
            @versions.detect do |v|
                v.split(".").slice(0, src_numbers_size) == src_numbers
            end
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

