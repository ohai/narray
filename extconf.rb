require "mkmf"

def have_type(type, header=nil)
  printf "checking for %s... ", type
  STDOUT.flush
  src = <<"SRC"
#include <ruby.h>
SRC
  unless header.nil?
  src << <<"SRC"
#include <#{header}>
SRC
  end
  r = try_link(src + <<"SRC")
  int main() { return 0; }
  int t() { #{type} a; return 0; }
SRC
  unless r
    print "no\n"
    return false
  end
  $defs.push(format("-DHAVE_%s", type.upcase))
  print "yes\n"
  return true
end

def create_conf_h(file)
  print "creating #{file}\n"
  hfile = open(file, "w")
  for line in $defs
    line =~ /^-D(.*)/
    hfile.printf "#define %s 1\n", $1
  end
  hfile.close
end

alias __install_rb :install_rb
def install_rb(mfile, dest, srcdir = nil)
  __install_rb(mfile, dest, srcdir)
  archdir = dest.sub(/sitelibdir/,"sitearchdir").sub(/rubylibdir/,"archdir")
  path = ['narray.h','narray_config.h']
  path << ['libnarray.a'] if RUBY_PLATFORM =~ /cygwin|mingw/
  for f in path
    mfile.printf "\t@$(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0644, true)' %s %s\n", f, archdir
  end
end

if RUBY_PLATFORM =~ /cygwin|mingw/
  CONFIG["DLDFLAGS"] << " --output-lib libnarray.a"
end

#$DEBUG = true
#$CFLAGS = ["-Wall",$CFLAGS].join(" ")

# configure options:
#  --with-fftw-dir=path
#  --with-fftw-include=path
#  --with-fftw-lib=path
dir_config("fftw")

srcs = %w(
narray
na_array
na_func
na_index
na_op
na_math
na_linalg
)

if have_header("sys/types.h")
  header = "sys/types.h"
else
  header = nil
end

have_type("u_int8_t", header)
have_type("int16_t", header)
have_type("int32_t", header)

#have_library("m")
have_func("sincos")
have_func("asinh")

if have_header("fftw.h")
  if have_library("fftw", "fftwnd_create_plan")
    srcs.push "na_fftw"
  else
    $defs.delete "-DHAVE_FFTW_H"
  end
end

$objs = srcs.collect{|i| i+".o"}

create_conf_h("narray_config.h")
create_makefile("narray")
