require "nginxbrew/version"
require "rake"

module Nginxbrew

    def run(command, env={})
        env.each{|k, v| ENV[k] = v }
        require "nginxbrew/tasks"
        Rake::Task[command].invoke
    end

    module_function :run
end

