
#
# Copyright (c) 2016 SUSE LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
use Mojo::Base -strict;

use Test::More;

use SUSE::BuildCheckStatistics::Util;

# Parsing RPMLint logs
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(''),
  {errors => [], warnings => []}, 'right structure';
is_deeply SUSE::BuildCheckStatistics::Util::parse_log('la la la'),
  {errors => [], warnings => []}, 'right structure';
my $result = {
  errors   => ['64bit-portability-issue', 'makefile-junk'],
  warnings => ['no-rpm-opt-flags',        'test-123']
};
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(
  <<'EOF'), $result, 'right structure';
test2-0.x86_64: W: no-rpm-opt-flags :./mkvmi.c, rfc2045acchk.c
test2-0.x86_64: W: test-123 :./mkvmi.c, rfc2045acchk.c
test2-0.x86_64: W: no-rpm-opt-flags :./mkvmi.c, rfc2045acchk.c
test2-0.x86_64: I: Program is using implicit definitions of special functions.
test2-0.x86_64: E: makefile-junk (Badness: 109) /usr/share/doc/Makefile
Your package contains makefiles that only make sense in a source package. Did
you package a complete directory from the tarball by using %doc? Consider
removing Makefile* from this directory at the end of your %install section to
reduce bloat.
test2-0.x86_64: E: 64bit-portability-issue unx/process.c:578, 627
EOF
$result = {
  errors   => ['64bit-portability-issue', 'makefile-junk'],
  warnings => ['no-rpm-opt-flags']
};
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(
  <<'EOF'), $result, 'right structure';
test2-0.x86_64: W: no-rpm-opt-flags :./mkvmi.c, rfc2045acchk.c
test2-0.x86_64: I: Program is using implicit definitions of special functions.
test2-0.x86_64: E: makefile-junk (Badness: 109) /usr/share/doc/Makefile
Your package contains makefiles that only make sense in a source package. Did
you package a complete directory from the tarball by using %doc? Consider
removing Makefile* from this directory at the end of your %install section to
reduce bloat.
test2-0.x86_64: E: 64bit-portability-issue unx/process.c:578, 627
EOF

done_testing;
