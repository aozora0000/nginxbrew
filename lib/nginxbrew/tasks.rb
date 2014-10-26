#!/usr/bin/env ruby
require "logger"
require "pathname"
require "fileutils"
require "nginxbrew/nginxes"


verbose(false)

$debug = ENV["NGINXBREW_DEBUG"].to_i == 1

$logger = Logger.new(STDOUT)
$logger.level = $debug ? Logger::DEBUG : Logger::ERROR


def package_name_from(version)
    "ngx-#{version}"
end


def version_from_package(name)
    prefix = "ngx-"
    idx = name.index(prefix)
    raise_abort "Invalid name #{name}" if idx < 0
    name.slice(prefix.size, name.size - 1)
end


def installed_packages(root)
    dest = {}
    return dest unless FileTest.directory?(root)
    Pathname.new(root).children.select{|e| e.directory? }.inject(dest) do |memo, d|
        version = version_from_package(File.basename(d))
        memo[version] = d
        memo
    end
end


def sh_exc(cmd, *opts)
    line = cmd
    line += " " + opts.join(" ")
    $logger.debug("#{line} dir=[#{Dir.pwd}]")
    line += " >/dev/null" unless $debug
    sh line
end


def raise_abort(msg)
    abort "[aborted] #{msg}"
end


OPENRESTY = "openresty-"

VERSION = ENV["VERSION"]
HOME_DIR = ENV["NGINXBREW_HOME"] || File.join(ENV["HOME"], "nginxbrew")
NGINX_USER = ENV["NGINXBREW_USER"] || "nginx"
NGINX_GROUP = ENV["NGINXBREW_GROUP"] || "nginx"

CONFIG_FILE = ENV["NGINXBREW_CONFIG"]
if CONFIG_FILE && !FileTest.file?(CONFIG_FILE)
    raise Exception.new("Specified configuration file #{CONFIG_FILE} is not found")
end


SOURCE_DIR = "#{HOME_DIR}/src"
DIST_DIR = "#{HOME_DIR}/versions"
BIN_DIR = "#{HOME_DIR}/bin"
NGINX_CURRENT_BIN_NAME = "#{BIN_DIR}/nginx"


[HOME_DIR, SOURCE_DIR, BIN_DIR, DIST_DIR].each do |dir|
    directory dir
end


if VERSION
    require "nginxbrew/config/base"

    is_openresty = VERSION.index(OPENRESTY) == 0

    # resolve version name
    $stdout.puts("checking version ...")
    nginxes = is_openresty ? Nginxbrew::Nginxes.openresties : Nginxbrew::Nginxes.nginxes
    version = nil
    raw_version = nil
    if is_openresty
        raw_version = nginxes.head_of(VERSION.slice(OPENRESTY.size, VERSION.size - 1))
        version = "#{OPENRESTY}#{raw_version}"
    else
        raw_version = nginxes.head_of(VERSION)
        version = raw_version
    end
    $stdout.puts("resolved version: [#{is_openresty ? 'openresty' : 'nginx'}-]#{raw_version}")


    Nginxbrew.config = Nginxbrew::Configuration.new(
        :home_dir => HOME_DIR,
        :dist_dir => DIST_DIR,
        :ngx_version => raw_version,
        :is_openresty => is_openresty,
        :ngx_user => NGINX_USER,
        :ngx_group => NGINX_GROUP
    )

    require "nginxbrew/config/default"
    require CONFIG_FILE if CONFIG_FILE
    $logger.debug(Nginxbrew.config.inspect)

    config = Nginxbrew.config

    directory config.dist_to

    TARBALL_DOWNLOADED_TO = File.join(SOURCE_DIR, config.tarball)
    SOURCE_EXTRACTED_TO = File.join(SOURCE_DIR, config.src)

    desc "get nginx tarball version:#{version}"
    file TARBALL_DOWNLOADED_TO => SOURCE_DIR do
        $stdout.puts("download #{config.version_name} from #{config.url}")
        Dir.chdir(SOURCE_DIR) do
            sh_exc("wget", config.url, "-q")
        end
    end


    desc "extract tarball, #{SOURCE_EXTRACTED_TO} will be created"
    directory SOURCE_EXTRACTED_TO => TARBALL_DOWNLOADED_TO do
        Dir.chdir(SOURCE_DIR) do
            sh_exc("tar", "zxf", TARBALL_DOWNLOADED_TO)
        end
    end


    desc "do build/install, after that create file:built to keep status of build"
    file config.builtfile => [SOURCE_EXTRACTED_TO, config.dist_to] do
        $stdout.puts("building #{config.version_name} ...")
        Dir.chdir(SOURCE_EXTRACTED_TO) do
            [config.configure_command, "gmake -j2", "gmake install"].each do |cmd|
                sh_exc(cmd)
            end
        end
        sh_exc("touch", config.builtfile)
    end


    desc "check nginx version duplication before install"
    task :check_duplicatate do
        if installed_packages(config.dist_dir).keys.include?(version)
            warn "#{config.version_name} is already installed"
        end
    end


    desc "install nginx"
    task :install => [:check_duplicatate, config.builtfile] do
        Rake::Task[:chown].invoke
        if installed_packages(DIST_DIR).size == 1
            $stdout.puts("this is first install, use this version as default")
            Rake::Task[:use].invoke
        end
    end


    desc "switch nginx version"
    task :use => [BIN_DIR, :chown] do
        raise_abort "#{config.version_name} is not installed!" unless FileTest.directory?(config.dist_to)
        FileUtils.ln_s(config.ngx_sbin_path, NGINX_CURRENT_BIN_NAME, :force => true)
        Rake::Task[:chown].invoke
        $stdout.puts("#{version} default to use")
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
    if FileTest.file?(NGINX_CURRENT_BIN_NAME)
        target_path = File.readlink(NGINX_CURRENT_BIN_NAME)
        path_list = target_path.split("/")
        2.times {|i| path_list.pop } # remove bin/nginx
        used_version = version_from_package(path_list.pop)
    end
    installed_packages(DIST_DIR).keys.sort.each do |v|
        prefix = (v == used_version) ? "*" : " "
        $stdout.puts("#{prefix} #{v}")
    end
end


desc "list nginx versions"
task :nginxes do
    HEAD_VERSION = ENV["HEAD_VERSION"]
    nginxes = Nginxbrew::Nginxes.nginxes
    ((HEAD_VERSION) ? nginxes.filter_versions(HEAD_VERSION) : nginxes.versions).each do |v|
        $stdout.puts("[nginx-]#{v}")
    end
end


desc "list openresty versions"
task :openresties do
    require "nginxbrew/nginxes"
    HEAD_VERSION = ENV["HEAD_VERSION"]
    nginxes = Nginxbrew::Nginxes.openresties
    ((HEAD_VERSION) ? nginxes.filter_versions(HEAD_VERSION) : nginxes.versions).each do |v|
        $stdout.puts("[ngx_openresty-]#{v}")
    end
end
