require "pathname"
require "fileutils"


module Nginxbrew

    class NamingConvention

        NGX = "ngx-"

        OPENRESTY = "openresty-" # <NGX>-<OPENRESTY>-x.x.x

        def self.resolve(version)
            is_openresty = openresty?(version)
            raw_version = is_openresty ? openresty_to_raw_version(version) : version
            [raw_version, is_openresty]
        end

        def self.openresty?(v)
            v.index(OPENRESTY) == 0
        end

        def self.openresty_to_raw_version(v)
            v.slice(OPENRESTY.size, v.size - 1)
        end

        def self.package_name_from(raw_version, is_openresty)
            "#{NGX}#{is_openresty ? OPENRESTY : ''}#{raw_version}"
        end

        def self.version_from_package(name)
            idx = name.index(NGX)
            if idx > -1
                ret = name.slice(NGX.size, name.size - 1).strip
                return ret if ret.size > 0
            end
            raise Exception.new("Invalid version name '#{name}'")
        end

    end

end

