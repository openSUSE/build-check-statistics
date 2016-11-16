
# SUSE::BuildCheckStatistics

  A [Mojolicious](http://mojolicious.org) application for collecting statistics
  about rpmlint failures in [Open Build Service](http://openbuildservice.org/)
  projects.

![Screenshot](https://raw.githubusercontent.com/openSUSE/build-check-statistics/master/screenshot.png)

## Installation

  All you need is a one-liner, it takes less than a minute.

    $ curl -L https://cpanmin.us | perl - -n git://github.com/openSUSE/build-check-statistics.git@master

  We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.

## Setup

Just create a configuration file under `/etc/build_check_statistics.conf`.

```
{
  username => 'obs_user',
  password => 'obs_password',
  protocol => 'https',
  host     => 'api.opensuse.org',
  projects => ['SomeProject', 'AnotherProject'],
  sqlite   => 'sqlite:test.db'
}
```

Or a different location chosen with the `SUSE_BCS_CONFIG` environment
variable.
```
SUSE_BCS_CONFIG=/home/sri/.build_check_statistics.conf
```

Update and deploy statistics. This can be repeated at any time to update the
data.
```
$ build_check_statistics update
$ build_check_statistics deploy
```

![Screenshot2](https://raw.githubusercontent.com/openSUSE/build-check-statistics/master/screenshot2.png)

Start the web server.
```
$ build_check_statistics daemon -m production
```
