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
package SUSE::BuildCheckStatistics::Updater;
use Mojo::Base -base;

use SUSE::BuildCheckStatistics::Util;
use Term::ProgressBar;

has 'app';
has silent => sub { $ENV{SUSE_BCS_SILENT} };

sub update {
  my $self = shift;

  my $app      = $self->app;
  my $packages = $app->packages;
  $packages->cleanup;
  my $obs = $app->config->{obs};

  # Repositories for projects
  my @repos;
  for my $project (@{$app->config->{projects}}) {
    next unless my $res = $self->_fetch("$obs/build/$project/_result");
    push @repos, [$project, @{$_}{qw(arch repository)}]
      for $res->dom->find('result')->each;
  }

  # Packages for repositories
  for my $r (@repos) {
    my ($project, $arch, $repo) = @$r;
    my $res = $self->_fetch(
      "$obs/build/$project/$repo/$arch/_jobhistory?code=lastfailures");
    next unless $res;

    my %pkgs;
    $pkgs{$_->{package}} = $_->{code} for $res->dom->find('jobhist')->each;

    # Log files for packages
    say "$project-$arch-$repo:" unless $self->silent;
    my $progress = Term::ProgressBar->new(
      {count => scalar keys %pkgs, term_width => 80, silent => $self->silent});
    for my $pkg (sort keys %pkgs) {
      my $code = $pkgs{$pkg} eq 'unchanged' ? 'succeeded' : $pkgs{$pkg};

      my $res
        = $self->_fetch("$obs/build/$project/$repo/$arch/$pkg/rpmlint.log");
      my $log
        = SUSE::BuildCheckStatistics::Util::parse_log($res ? $res->body : '');

      $packages->stage($project, $repo, $arch, $pkg, $code, $log);
      $progress->update;
    }
    say '' unless $self->silent;
  }
}

sub _fetch {
  my ($self, $url) = @_;

  my $tx = $self->app->ua->get($url);
  if (my $res = $tx->success) { return $res }

  my $err = $tx->error;
  if (my $code = $err->{code}) {
    die "Authorization required.\n" if $code eq '401';
    return undef;
  }
  die "Connection error: $err->{message}";
}

1;
