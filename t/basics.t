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

use Mojo::Server::Daemon;
use Mojolicious::Lite;
use Test::Mojo;

get '/build/Foo/_result' => {data => <<'EOF'};
<resultlist state="d2849004daf01a865181a1784e8a0980">
  <result project="Foo" repository="Bar" arch="i586">
    <status package="baz" code="succeeded" />
    <status package="yada" code="succeeded" />
  </result>
  <result project="Foo" repository="Bar" arch="x86_64">
    <status package="baz" code="succeeded" />
    <status package="yada" code="disabled" />
  </result>
</resultlist>
EOF

get '/build/Foo/Bar/i586/_jobhistory' => {data => <<'EOF'};
<jobhistlist>
    <jobhist package="baz" code="failed" />
    <jobhist package="baz" code="succeeded" />
    <jobhist package="yada" code="succeeded" />
</jobhistlist>
EOF

get '/build/Foo/Bar/x86_64/_jobhistory' => {data => <<'EOF'};
<jobhistlist>
    <jobhist package="baz" code="succeeded" />
    <jobhist package="yada" code="failed" />
</jobhistlist>
EOF

get '/build/Foo/Bar/i586/baz/rpmlint.log' => {data => <<'EOF'};
baz-0.i586: W: no-rpm-opt-flags
baz-0.i586: E: test-123
baz-0.i586: W: whatever
EOF

get '/build/Foo/Bar/i586/yada/rpmlint.log' => {data => <<'EOF'};
baz-0.i586: W: no-rpm-opt-flags
EOF

get '/build/Foo/Bar/x86_64/yada/rpmlint.log' => {data => <<'EOF'};
baz-0.i586: W: no-rpm-opt-flags
EOF

any '/*' => {'' => '', data => 'Not found!', status => 404};

# OBS test server
my $daemon
  = Mojo::Server::Daemon->new(app => app, listen => ['http://127.0.0.1'])
  ->start;
my $port = Mojo::IOLoop->acceptor($daemon->acceptors->[0])->port;

# No data yet
my $t      = Test::Mojo->new('SUSE::BuildCheckStatistics');
my $config = {obs => "http://127.0.0.1:$port", projects => ['Foo']};
my $app    = $t->app;
$app->config($config);
$app->sqlite->from_string('sqlite::temp:');
$t->get_ok('/')->content_like(qr/No data yet, forgot to update and deploy\?/);

# Update and deploy
$app->ua->ioloop(Mojo::IOLoop->singleton);
my $db = $app->sqlite->db;
is $db->query('select count(*) from staging')->array->[0],  0, 'no packages';
is $db->query('select count(*) from packages')->array->[0], 0, 'no packages';
$app->updater->silent(1)->update;
is $db->query('select count(*) from staging')->array->[0],  4, 'four packages';
is $db->query('select count(*) from packages')->array->[0], 0, 'no packages';
$app->packages->deploy;
is $db->query('select count(*) from staging')->array->[0],  0, 'no packages';
is $db->query('select count(*) from packages')->array->[0], 4, 'four packages';

# Deployed
my $results
  = $db->query('select id, code, package, errors, warnings from packages')
  ->expand(json => [qw(errors warnings)]);
my $all = [
  {
    id       => 1,
    code     => 'succeeded',
    package  => 'baz',
    errors   => ['test-123'],
    warnings => ['no-rpm-opt-flags', 'whatever']
  },
  {
    id       => 2,
    code     => 'succeeded',
    package  => 'yada',
    errors   => [],
    warnings => ['no-rpm-opt-flags']
  },
  {
    id       => 3,
    code     => 'succeeded',
    package  => 'baz',
    errors   => [],
    warnings => []
  },
  {
    id       => 4,
    code     => 'failed',
    package  => 'yada',
    errors   => [],
    warnings => ['no-rpm-opt-flags']
  }
];
is_deeply $results->hashes->to_array, $all, 'right structure';

# Dashboard
$t->get_ok('/')->text_like(title => qr/Build Check Statistics/)
  ->content_unlike(qr/No data yet, forgot to update and deploy\?/)
  ->content_like(qr/Last updated:/)
  ->text_like('td a[href=/rules/Foo/i586/Bar]'   => qr/Foo-i586-Bar/)
  ->text_like('td a[href=/Foo/x86_64/Bar]'       => qr/2 packages/)
  ->text_like('td a[href=/rules/Foo/x86_64/Bar]' => qr/Foo-x86_64-Bar/)
  ->text_like('td a[href=/Foo/x86_64/Bar]'       => qr/2 packages/);

# Rules
$t->get_ok('/rules/Foo/i586/Bar')
  ->text_like(title => qr/Build Check Statistics/)
  ->content_like(qr/Foo-i586-Bar/)
  ->text_like('a[href=/Foo/i586/Bar?rule=no-rpm-opt-flags]' => qr/2 packages/);

# Packages
$t->get_ok('/Foo/i586/Bar')->text_like(title => qr/Build Check Statistics/)
  ->content_like(qr/Foo-i586-Bar/)->text_like('a[href=/2]' => qr/yada/);
$t->get_ok('/Foo/i586/Bar?rule=no-rpm-opt-flags')->status_is(200)
  ->content_like(qr/Foo-i586-Bar: no-rpm-opt-flags/)
  ->text_like('a[href=/1]' => qr/baz/);

# Info
$t->get_ok('/1')->text_like(title => qr/Build Check Statistics/)
  ->content_like(qr/Foo-i586-Bar: baz/)
  ->text_like('a[href=/Foo/i586/Bar?rule=no-rpm-opt-flags]' => qr/1 package/);

# Log
$t->get_ok('/log/1')->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_like(qr/no-rpm-opt-flags/);

done_testing;
