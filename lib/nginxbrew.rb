require "rake"

require "nginxbrew/version"
require "nginxbrew/catalog"
require "nginxbrew/local"
require "nginxbrew/convention"
require "nginxbrew/rake_tools"


module Nginxbrew

    def run(command, env={})
        env.each{|k, v| ENV[k] = v }
        require "nginxbrew/tasks"
        Rake::Task[command].invoke
    end

    module_function :run
end

