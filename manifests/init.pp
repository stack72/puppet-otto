# Public: Installs a version of otto
#
# Params:
#
#  ensure  -- must be present or absent, default present
#  root    -- the path to install otto to, see otto::params for default
#  user    -- the user to install otto as, see otto::params for default
#  version -- the version of otto to ensure, see otto::params for default

class otto(
  $ensure  = present,
  $root    = $otto::params::root,
  $user    = $otto::params::user,
  $version = $otto::params::version,
) inherits otto::params {

  case $ensure {
    present: {
      # get the download URI
      $download_uri = "https://dl.bintray.com/mitchellh/otto/otto_${version}_${otto::params::_real_platform}.zip?direct"

      # the dir inside the zipball uses the major version number segment
      $major_version = split($version, '[.]')
      $extracted_dirname = $major_version[0]

      $install_command = join([
        # blow away any previous attempts
        "rm -rf /tmp/otto* /tmp/${extracted_dirname}",
        # download the zip to tmp
        "curl ${download_uri} -L > /tmp/otto-v${version}.zip",
        # extract the zip to tmp spot
        'mkdir /tmp/otto',
        "unzip -o /tmp/otto-v${version}.zip -d /tmp/otto",
        # blow away an existing version if there is one
        "rm -rf ${root}",
        # move the directory to the root
        "mv /tmp/otto ${root}",
        # chown it
        "chown -R ${user} ${root}"
      ], ' && ')

      exec {
        "install otto v${version}":
          command => $install_command,
          unless  => "test -x ${root}/otto && ${root}/otto -v | grep '\\bv${version}\\b'",
          user    => $user,
      }

      if $::operatingsystem == 'Darwin' {
        include boxen::config

        boxen::env_script { 'otto':
          content  => template('otto/env.sh.erb'),
          priority => 'lower',
        }

        file { "${boxen::config::envdir}/otto.sh":
          ensure => absent,
        }
      }
    }

    absent: {
      file { $root:
        ensure  => absent,
        recurse => true,
        force   => true,
      }
    }

    default: {
      fail('Ensure must be present or absent')
    }
  }
}

