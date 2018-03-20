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
use Mojo::File 'path';
use SUSE::BuildCheckStatistics::Util;

my $rpmlint = path(__FILE__)->dirname->child('rpmlint');

# Errors and warnings
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(''),
  {errors => [], info => [], warnings => []}, 'right structure';
is_deeply SUSE::BuildCheckStatistics::Util::parse_log('la la la'),
  {errors => [], info => [], warnings => []}, 'right structure';

# "blueman.log"
my $result = {
  errors   => ['env-script-interpreter'],
  info     => ['polkit-cant-acquire-privilege', 'polkit-untracked-privilege'],
  warnings => ['empty-%post', 'empty-%postun', 'invalid-desktopfile']
};
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(
  $rpmlint->child('blueman.log')->slurp), $result, 'right structure';

# "samba.log"
$result = {
  errors   => ['devel-file-in-non-devel-package', 'env-script-interpreter'],
  info     => ['binary-or-shlib-calls-gethostbyname'],
  warnings => [
    'call-to-mktemp',
    'dangling-symlink',
    'empty-%pre',
    'filename-too-long-for-joliet',
    'macro-in-comment',
    'missing-call-to-chdir-with-chroot',
    'no-dependency-on',
    'no-description-tag',
    'non-conffile-in-etc',
    'non-etc-or-var-file-marked-as-conffile',
    'non-executable-script',
    'non-standard-gid',
    'non-standard-group',
    'obsolete-not-provided',
    'perl5-naming-policy-not-applied',
    'postin-without-tmpfile-creation',
    'script-without-shebang',
    'self-obsoletion',
    'shlib-policy-missing-suffix',
    'suse-logrotate-log-dir-not-packaged',
    'suse-missing-rclink',
    'tmpfile-not-in-filelist',
    'wrong-file-end-of-line-encoding',
    'zero-length'
  ]
};
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(
  $rpmlint->child('samba.log')->slurp), $result, 'right structure';

# "virtualbox.log"
$result = {
  errors   => [],
  info     => ['binary-or-shlib-calls-gethostbyname'],
  warnings => [
    'description-shorter-than-summary',
    'empty-%post',
    'empty-%posttrans',
    'explicit-lib-dependency',
    'incoherent-init-script-name',
    'macro-in-comment',
    'missing-call-to-setgroups-before-setuid',
    'missing-lsb-keyword',
    'name-repeated-in-summary',
    'non-conffile-in-etc',
    'non-standard-gid',
    'obsolete-not-provided',
    'permissions-incorrect',
    'position-independent-executable-suggested',
    'rpm-buildroot-usage',
    'shared-lib-calls-exit',
    'standard-dir-owned-by-package',
    'suse-deprecated-init-script',
    'suse-filelist-forbidden-fhs23',
    'suse-filelist-forbidden-udev-userdirs',
    'suse-missing-rclink',
    'suse-obsolete-insserv-requirement',
    'systemd-service-without-service_add_post',
    'systemd-service-without-service_add_pre',
    'systemd-service-without-service_del_postun',
    'systemd-service-without-service_del_preun',
    'udev-rule-in-etc',
    'unstripped-binary-or-object',
    'useless-provides'
  ]
};
is_deeply SUSE::BuildCheckStatistics::Util::parse_log(
  $rpmlint->child('virtualbox.log')->slurp), $result, 'right structure';

done_testing;
