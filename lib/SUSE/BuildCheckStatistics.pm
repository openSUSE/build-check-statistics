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
package SUSE::BuildCheckStatistics;
use Mojo::Base 'Mojolicious';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Mojo::SQLite;
use Scalar::Util 'weaken';
use SUSE::BuildCheckStatistics::Model::Packages;
use SUSE::BuildCheckStatistics::Updater;

has updater => sub {
  my $self = shift;
  my $updater = SUSE::BuildCheckStatistics::Updater->new(app => $self);
  weaken $updater->{app};
  return $updater;
};

our $VERSION = '1.08';

sub startup {
  my $self = shift;

  # Switch to installable home directory
  my $home = $self->home;
  $home->parse(catdir(dirname(__FILE__), 'BuildCheckStatistics', 'resources'));
  $self->static->paths->[0]   = $home->rel_dir('public');
  $self->renderer->paths->[0] = $home->rel_dir('templates');

  # Application specific commands
  push @{$self->commands->namespaces}, 'SUSE::BuildCheckStatistics::Command';

  # Our user agent needs to receive huge log files
  $self->ua->on(start => sub { pop->res->max_message_size(134217728) });

  # No defaults
  my $config = $self->plugin(
    Config => {
      default => {},
      file    => $ENV{SUSE_BCS_CONFIG} || '/etc/build_check_statistics.conf'
    }
  );
  $self->plugin('SUSE::BuildCheckStatistics::Plugin::TagHelpers');

  # Model
  $self->helper(
    sqlite => sub { state $sqlite = Mojo::SQLite->new($config->{sqlite}) });
  $self->helper(
    packages => sub {
      state $pkgs = SUSE::BuildCheckStatistics::Model::Packages->new(
        sqlite => shift->sqlite);
    }
  );

  # Migrate automatically to latest version
  my $path = $home->rel_file('migrations/build_check_statistics.sql');
  $self->sqlite->auto_migrate(1)->migrations->name('build_check_statistics')
    ->from_file($path);

  # Controller
  my $r = $self->routes;
  $r->get('/rules/#project/#arch/#repo')->to('packages#rules')->name('rules');
  $r->get('/#project/#arch/#repo')->to('packages#repo')->name('repo');
  $r->get('/log/:id')->to('packages#log')->name('log');
  $r->get('/:id')->to('packages#info')->name('info');
  $r->get('/')->to('packages#dashboard');
}

1;
