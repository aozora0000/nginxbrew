#!/usr/bin/env ruby
require "fileutils"

verbose(false) # stop verbosing by rake


HOME_DIR = ENV["NGINXBREW_HOME"] || File.join(ENV["HOME"], "nginxbrew")
$stdout.puts("using '#{HOME_DIR}' as nginxbrew home") if ENV["NGINXBREW_HOME"]


CONFIG_FILE = ENV["NGINXBREW_CONFIG"]
$stdout.puts("using '#{CONFIG_FILE}' as nginxbrew config") if CONFIG_FILE


SOURCE_DIR = "#{HOME_DIR}/.src"
DIST_DIR = "#{HOME_DIR}/versions"
BIN_DIR = "#{HOME_DIR}/bin"
NGINX_BIN = "#{BIN_DIR}/nginx"
CACHE_DIR = "#{HOME_DIR}/.cache"


[HOME_DIR, SOURCE_DIR, BIN_DIR, DIST_DIR].each do |dir|
    directory dir
end


if ENV["VERSION"]
    require "nginxbrew/config/base"

    $stdout.puts("checking version ...")
    raw_version, is_openresty = NamingConvention.resolve(ENV["VERSION"])

    nginxes = is_openresty ? Nginxbrew::Catalog.openresties(cache_dir=CACHE_DIR) :
        Nginxbrew::Catalog.nginxes(cache_dir=CACHE_DIR)

    raw_version = nginxes.head_of(raw_version)
    package_name = NamingConvention.package_name_from(raw_version, is_openresty)
    $stdout.puts("resolved version: [#{is_openresty ? 'openresty' : 'nginx'}-]#{raw_version}")
    $stdout.puts("nginx package: #{package_name}")

    Nginxbrew.config = Nginxbrew::Configuration.new(
        :home_dir => HOME_DIR,
        :dist_dir => DIST_DIR,
        :ngx_version => raw_version,
        :package_name => package_name,
        :is_openresty => is_openresty
    )

    require "nginxbrew/config/default"
    require CONFIG_FILE if CONFIG_FILE
    $logger.debug(Nginxbrew.config.inspect)

    config = Nginxbrew.config

    directory config.dist_to

    tarball_download_to = File.join(SOURCE_DIR, config.tarball)
    source_extract_to = File.join(SOURCE_DIR, config.src)

    desc "get nginx tarball version:#{config.package_name}"
    file tarball_download_to => SOURCE_DIR do
        $stdout.puts("download #{config.package_name} from #{config.url}")
        Dir.chdir(SOURCE_DIR) do
            sh_exc("wget", config.url, "-q")
        end
    end


    desc "extract tarball, #{source_extract_to} will be created"
    directory source_extract_to => tarball_download_to do
        Dir.chdir(SOURCE_DIR) do
            sh_exc("tar", "zxf", tarball_download_to)
        end
    end


    desc "do build/install, after that create file:built to keep status of build"
    file config.builtfile => [source_extract_to, config.dist_to] do
        $stdout.puts("building #{config.package_name} ...")
        Dir.chdir(source_extract_to) do
            [config.configure_command, "gmake -j2", "gmake install"].each do |cmd|
                sh_exc(cmd)
            end
        end
        sh_exc("touch", config.builtfile)
    end


    desc "check nginx version duplication before install"
    task :check_duplicatate do
        unless Nginxbrew::Local.find(config).nil?
            warn "#{config.package_name} is already installed"
        end
    end


    desc "install nginx"
    task :install => [:check_duplicatate, config.builtfile] do
        Rake::Task[:chown].invoke
        if Nginxbrew::Local.count_of_builds(config.dist_dir) == 1
            $stdout.puts("this is first install, use this version as default")
            Rake::Task[:use].invoke
        end
    end


    desc "switch nginx version"
    task :use => [BIN_DIR, :chown] do
        ngx = Nginxbrew::Local.find(config)
        unless FileTest.directory?(config.dist_to)
            raise_abort "#{config.package_name} is not installed!"
        end
        FileUtils.ln_s(config.ngx_sbin_path, NGINX_BIN, :force => true)
        Rake::Task[:chown].invoke
        $stdout.puts("#{config.package_name} default to use")
        $stdout.puts("bin linked to #{config.ngx_sbin_path}")
    end

end


desc "chown to sudo user or normal user"
task :chown do
    sudo_user = ENV["SUDO_USER"]
    user = ENV["USER"]
    if sudo_user && sudo_user != user
        [HOME_DIR, DIST_DIR, BIN_DIR].each do |dir|
            sh_exc("chown", "-R", sudo_user, dir) if FileTest.directory?(dir)
        end    
    end
end


desc "list installed nginx"
task :list => DIST_DIR do
    used_version = nil
    if FileTest.file?(NGINX_BIN)
        target_path = File.readlink(NGINX_BIN)
        path_list = target_path.split("/")
        2.times {|i| path_list.pop } # remove bin/nginx
        used_version = NamingConvention.version_from_package(path_list.pop)
    end
    Nginxbrew::Local.builds(DIST_DIR).each do |ngx|
        prefix = ngx.is?(used_version) ? "*" : " "
        $stdout.puts("#{prefix} #{ngx.name}")
    end
end


desc "list nginx versions"
task :nginxes do
    HEAD_VERSION = ENV["HEAD_VERSION"]
    nginxes = Nginxbrew::Catalog.nginxes(cache_dir=CACHE_DIR)
    ((HEAD_VERSION) ? nginxes.filter_versions(HEAD_VERSION) : nginxes.versions).each do |v|
        $stdout.puts("[nginx-]#{v}")
    end
end


desc "list openresty versions"
task :openresties do
    HEAD_VERSION = ENV["HEAD_VERSION"]
    nginxes = Nginxbrew::Catalog.openresties(cache_dir=CACHE_DIR)
    ((HEAD_VERSION) ? nginxes.filter_versions(HEAD_VERSION) : nginxes.versions).each do |v|
        $stdout.puts("[ngx_openresty-]#{v}")
    end
end


desc "Output  new configfile for nginxbrew into specified path as {MAKECONF_OUTPUT_TO}"
task :makeconf do
    output_to = ENV["MAKECONF_OUTPUT_TO"]

    from_file = File.join(File.dirname(__FILE__), "config/default.rb")
    abort "crit, #{from_file} is not found" unless FileTest.file?(from_file)

    to_file = FileTest.directory?(output_to) ?
        File.join(output_to, "nginxbrew_conf.rb") : output_to
    to_file = File.expand_path(to_file)
    abort "config:'#{to_file}' is alrady exists!" if FileTest.file?(to_file)
    abort "extname is must be '.rb'" if File.extname(to_file) != ".rb"

    sh_exc("cp", from_file, to_file)

    msg =<<-EOF
'#{to_file}' is created, successfully.
You can use this configuration by env NGINXBREW_CONFIG like as follows.

 $ export NGINXBREW_CONFIG=#{to_file}

  or

 $ echo "export NGINXBREW_CONFIG=#{to_file}" >> ~/.bashrc && source ~/.bashrc
    EOF

    $stdout.puts(msg)
end

