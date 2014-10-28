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
