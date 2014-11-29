require "net/http"
require "uri"
require "fileutils"

include Nginxbrew


module Nginxbrew

    class VersionNotFoundError < StandardError

        def initialize(v)
            super("version '#{v}' is not found in all versions of nginxes/openresties")
        end

    end

    class Catalog

        TypeNginx = "nginx"

        TypeOpenresty = "openresty"

        CacheExpireDays = 1

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

        def unsupport_under!(version)
            min_version = Gem::Version.new(version)
            @versions = @versions.select do |v|
                Gem::Version.new(v) >= min_version
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

        def self.nginxes(cache_dir=nil)
            catalog_cache_or(cache_dir, "nginxes") do
                versions = html_body_of("http://nginx.org", "/download/").
                    gsub(/href="nginx\-([0-9\.]+?)\.tar\.gz"/).inject([]) do |memo, match|
                        memo << $1
                        memo
                end
                c = Catalog.new(TypeNginx, versions)
                c.unsupport_under!("0.5.38") # can not build under this version
                c
            end
        end

        def self.openresties(cache_dir=nil)
            catalog_cache_or(cache_dir, "openresties") do
                versions = html_body_of("http://openresty.org", "/").
                    gsub(/ngx_openresty\-([0-9\.]+?)\.tar\.gz/).inject([]) do |memo, match|
                        memo << $1
                        memo
                end
                Catalog.new(TypeOpenresty, versions)
            end
        end

        private

        def self.catalog_cache_or(dir, key, &block)
            return block.call if !dir || !key

            cache_dir = File.join(dir, "catalog")
            FileUtils.mkdir_p(cache_dir) unless FileTest.directory?(cache_dir)

            cache_file = File.join(cache_dir, "#{key}.ca")

            if FileTest.file?(cache_file)
                expired = File.mtime(cache_file) + CacheExpireDays * 24 * 60 * 60
                if Time.now < expired
                    $logger.debug("Cache file: #{cache_file}")
                    begin
                        return Marshal.load(File.binread(cache_file))
                    rescue Exception => e
                        File.delete(cache_file)
                        $logger.error("#{e}")
                        $logger.error("#{cache_file} removed")
                    end
                else
                    File.delete(cache_file)
                end
            end

            dest = block.call
            File.binwrite(cache_file, Marshal.dump(dest))
            $logger.debug("Cache saved to #{cache_file}")

            dest
        end

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

