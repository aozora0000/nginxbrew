require "fileutils"

module Nginxbrew

    module Local
    
        class Ngx
        
            attr_reader :is_openresty, :raw_version, :version

            def initialize(opts={})
                @is_openresty = opts[:is_openresty]
                @raw_version = opts[:raw_version]
                @version = opts[:version]
            end

            def is?(version)
                @version == version
            end

            def openresty?
                @is_openresty
            end

            def name
                @version
            end

        end

        def builds(dist_dir)
            dest = []
            return dest unless FileTest.directory?(dist_dir)
            child_dirs = Pathname.new(dist_dir).children.select{|e| e.directory? }
            child_dirs.inject(dest) do |memo, d|
                version = NamingConvention.version_from_package(File.basename(d))
                is_openresty = NamingConvention.openresty?(version)
                raw_version = is_openresty ?
                    NamingConvention.openresty_to_raw_version(version) : version
                $logger.debug("built package: #{d} -> #{is_openresty}, #{raw_version}")
                memo << Ngx.new(
                    :is_openresty => is_openresty,
                    :raw_version => raw_version,
                    :version => version
                )
                memo
            end
        end

        def find(config)
            builds(config.dist_dir).detect do |b|
                b.raw_version == config.ngx_version &&
                    b.is_openresty == config.is_openresty
            end
        end

        def count_of_builds(dist_dir)
            builds(dist_dir).size
        end

        module_function :builds, :find, :count_of_builds

    end

end

