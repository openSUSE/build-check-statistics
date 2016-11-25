
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
  obs       => 'https://build.opensuse.org/public',
  projects  => ['SomeProject', 'AnotherProject'],
  sqlite    => 'sqlite:/var/lib/build_check_statistics/test.db',
  hypnotoad => {
    pid_file => '/var/lib/build_check_statistics/hypnotoad.pid'
  }
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

## openSUSE Installation

There are also openSUSE packages available.

```
zypper ar -f obs://home:kraih/openSUSE_Tumbleweed bcs

zypper in perl-SUSE-BuildCheckStatistics
zypper in apache2

vim /etc/build_check_statistics.conf

systemctl start bcs-web.service
systemctl start bcs-update.timer
systemctl start bcs-update.service

a2enmod headers
a2enmod proxy
a2enmod proxy_http

cp /etc/apache2/vhosts.d/build_check_statistics.conf.template \
  /etc/apache2/vhosts.d/build_check_statistics.conf
vim /etc/apache2/vhosts.d/build_check_statistics.conf

systemctl restart apache2
```
