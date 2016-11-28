use 5.010001;

use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'SUSE::BuildCheckStatistics',
  VERSION_FROM => 'lib/SUSE/BuildCheckStatistics.pm',
  ABSTRACT     => 'Build Check Statistics',
  AUTHOR       => 'Sebastian Riedel <sri@cpan.org>',
  LICENSE      => 'MIT',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['t']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
      bugtracker =>
        {web => 'https://github.com/openSUSE/build-check-statistics/issues'},
      homepage   => 'https://github.com/openSUSE/build-check-statistics',
      license    => ['https://opensource.org/licenses/MIT'],
      repository => {
        type => 'git',
        url  => 'https://github.com/openSUSE/build-check-statistics.git',
        web  => 'https://github.com/openSUSE/build-check-statistics',
      },
      x_IRC => 'irc://irc.freenode.org/#suse'
    },
  },
  PREREQ_PM => {
    Mojolicious         => '7.10',
    'Mojo::SQLite'      => '1.000',
    'Term::ProgressBar' => '2.17'
  },
  EXE_FILES => ['bin/build_check_statistics'],
  test      => {TESTS => 't/*.t t/*/*.t'}
);
