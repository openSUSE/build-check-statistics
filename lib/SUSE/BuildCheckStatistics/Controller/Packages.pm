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
package SUSE::BuildCheckStatistics::Controller::Packages;
use Mojo::Base 'Mojolicious::Controller';

use 5.24.0;
use experimental 'signatures';

sub dashboard ($self) {
  my $packages = $self->packages;
  $self->render(stats => $packages->stats, updated => $packages->last_updated);
}

sub info ($self) {
  $self->render(pkg => $self->packages->pkg_for_id($self->stash('id')));
}

sub log ($self) {
  my ($arch, $pkg, $project, $repo)
    = $self->packages->pkg_for_id($self->stash('id'))
    ->@{qw(arch package project repository)};

  my $base = $self->app->updater->base;
  $self->ua->get(
    "$base/build/$project/$repo/$arch/$pkg/rpmlint.log" => sub ($ua, $tx) {
      my $res = $tx->res;
      $self->render(data => $res->body, status => $res->code, format => 'txt');
    }
  );
}

sub repo ($self) {
  my $pkgs
    = $self->packages->pkgs_for_repo($self->stash->@{qw(project arch repo)},
    $self->param('rule'));
  @$pkgs = grep { !!$_->{errors}->@* || !!$_->{warnings}->@* } $pkgs->@*;
  $self->render(pkgs => $pkgs);
}

sub rules ($self) {
  my $rules
    = $self->packages->rules_for_repo($self->stash->@{qw(project arch repo)});
  $self->render(rules => $rules);
}

1;
