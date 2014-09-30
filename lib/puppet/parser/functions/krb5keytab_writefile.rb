module Puppet::Parser::Functions
  newfunction(:krb5keytab_writefile, :type => :rvalue) do |args|
    require 'tempfile'
    tmpfile = Tempfile.new('tmpfile')
    tmpfile.write(args[0])
    tmpfile.close
    return tmpfile.path
  end
end
