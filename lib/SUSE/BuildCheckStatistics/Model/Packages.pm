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
package SUSE::BuildCheckStatistics::Model::Packages;
use Mojo::Base -base;

has 'sqlite';

sub cleanup { shift->sqlite->db->query('delete from staging') }

sub deploy {
  my $self = shift;

  my $db = $self->sqlite->db;
  my $tx = $db->begin;
  $db->query('delete from packages');
  $db->query(
    'insert into packages (
       arch, code, errors, info, package, project, repository, updated,
       warnings
     )
     select arch, code, errors, info, package, project, repository, updated,
       warnings
     from staging'
  );
  $db->query('delete from staging');
  $tx->commit;
}

sub pkg_for_id {
  my ($self, $id) = @_;

  my $db = $self->sqlite->db;
  my $hash = $db->query('select * from packages where id = ?', $id)
    ->expand(json => [qw(errors info warnings)])->hash;

  my ($project, $arch, $repo) = @{$hash}{qw(project arch repository)};
  $hash->{rules} = {
    map { $_ => $self->_pkgs_for_rule($project, $arch, $repo, $_) }
    map {@$_} @{$hash}{qw(errors info warnings)},
  };

  return $hash;
}

sub pkgs_for_repo {
  my ($self, $project, $arch, $repo, $rule) = @_;

  my $db     = $self->sqlite->db;
  my $errors = $db->query(
    'select packages.id, package, code, errors, info, warnings from packages,
       json_each(packages.errors)
     where project = ? and arch = ? and repository = ?
       and json_each.value = coalesce(?, json_each.value)
     group by project, arch, repository, package', $project, $arch, $repo, $rule
  )->expand(json => [qw(errors info warnings)])->hashes;
  my $pkgs = $errors->reduce(sub { $a->{$b->{id}} = $b; $a }, {});

  my $info = $db->query(
    'select packages.id, package, code, errors, info, warnings from packages,
       json_each(packages.info)
     where project = ? and arch = ? and repository = ?
       and json_each.value = coalesce(?, json_each.value)
     group by project, arch, repository, package', $project, $arch, $repo, $rule
  )->expand(json => [qw(errors info warnings)])->hashes;
  $pkgs = $info->reduce(sub { $a->{$b->{id}} ||= $b; $a }, $pkgs);

  my $warnings = $db->query(
    'select packages.id, package, code, errors, info, warnings from packages,
       json_each(packages.warnings)
     where project = ? and arch = ? and repository = ?
       and json_each.value = coalesce(?, json_each.value)
     group by project, arch, repository, package', $project, $arch, $repo, $rule
  )->expand(json => [qw(errors info warnings)])->hashes;
  $pkgs = $warnings->reduce(sub { $a->{$b->{id}} ||= $b; $a }, $pkgs);

  return [sort { $b->{id} <=> $a->{id} } values %$pkgs];
}

sub last_updated {
  my $self  = shift;
  my $array = $self->sqlite->db->query(
    'select updated from packages order by updated desc limit 1')->array;
  return $array ? $array->[0] : undef;
}

sub rules_for_repo {
  my ($self, $project, $arch, $repo) = @_;

  my $db    = $self->sqlite->db;
  my @rules = $db->query(
    "select e.value as rule, count(package) as packages, 'error' as type
     from packages, json_each(packages.errors) as e
     where project = ? and arch = ? and repository = ?
     group by e.value", $project, $arch, $repo
  )->hashes->each;

  push @rules, $db->query(
    "select i.value as rule, count(package) as packages, 'info' as type
     from packages, json_each(packages.info) as i
     where project = ? and arch = ? and repository = ?
     group by i.value", $project, $arch, $repo
  )->hashes->each;

  push @rules, $db->query(
    "select w.value as rule, count(package) as packages, 'warning' as type
     from packages, json_each(packages.warnings) as w
     where project = ? and arch = ? and repository = ?
     group by w.value", $project, $arch, $repo
  )->hashes->each;

  return \@rules;
}

sub stage {
  my ($self, $project, $repo, $arch, $pkg, $code, $log) = @_;
  $self->sqlite->db->query(
    'insert into staging (
       arch, code, errors, info, package, project, repository, warnings)
     values (?, ?, ?, ?, ?, ?, ?, ?)', $arch, $code, {json => $log->{errors}},
    {json => $log->{info}}, $pkg, $project, $repo, {json => $log->{warnings}}
  );
}

sub stats {
  shift->sqlite->db->query(
    "select project, arch, repository, count(package) as packages,
       sum(json_array_length(errors)) as errors,
       sum(json_array_length(info)) as info,
       sum(json_array_length(warnings)) as warnings
     from packages where (errors != '[]' or info != '[]' or warnings != '[]')
     group by project, arch, repository"
  )->hashes;
}

sub _pkgs_for_rule {
  my ($self, $project, $arch, $repo, $rule) = @_;

  my $db       = $self->sqlite->db;
  my @packages = $db->query(
    'select package from packages, json_each(packages.errors)
     where project = ? and arch = ? and repository = ?
       and json_each.value = ?', $project, $arch, $repo, $rule
  )->arrays->map(sub { $_->[0] })->each;

  push @packages, $db->query(
    'select package from packages, json_each(packages.info)
     where project = ? and arch = ? and repository = ?
       and json_each.value = ?', $project, $arch, $repo, $rule
  )->arrays->map(sub { $_->[0] })->each;

  push @packages, $db->query(
    'select package from packages, json_each(packages.warnings)
     where project = ? and arch = ? and repository = ?
       and json_each.value = ?', $project, $arch, $repo, $rule
  )->arrays->map(sub { $_->[0] })->each;

  return \@packages;
}

1;
