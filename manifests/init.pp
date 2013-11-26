define duplicity(
  $ensure = 'present',
  $directory = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $passphrase = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $post_command = undef,
  $remove_older_than = undef,
) {

  include duplicity::params

  package {
    ['duplicity', 'python-boto']: ensure => present
  }

  file {
      "duplicity_${name}_logdir":
          ensure  => directory,
          path    => '/var/log/duplicity',
          owner   => 'root',
          group   => 'root',
          mode    => '0640'
  }

  $escapedname = regsubst("${name}.sh", '[/]', '', 'G')
  $escapedlogname = regsubst("${name}.log", '[/]', '', 'G')
  $spoolfile = "${duplicity::params::job_spool}/${escapedname}"
  $spoolfile_command = "${spoolfile} >> /var/log/duplicity/${escapedlogname} 2>&1"

  duplicity::job { $name :
    ensure             => $ensure,
    spoolfile          => $spoolfile,
    directory          => $directory,
    bucket             => $bucket,
    dest_id            => $dest_id,
    dest_key           => $dest_key,
    folder             => $folder,
    cloud              => $cloud,
    passphrase         => $passphrase,
    full_if_older_than => $full_if_older_than,
    pre_command        => $pre_command,
    post_command       => $post_command,
    remove_older_than  => $remove_older_than,
  }

  $_hour = $hour ? {
    undef   => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef   => $duplicity::params::minute,
    default => $minute
  }

  cron { $name :
    ensure  => $ensure,
    command => $spoolfile_command,
    user    => 'root',
    minute  => $_minute,
    hour    => $_hour,
    require => File["duplicity_${name}_logdir"]
  }

  File[$spoolfile]->Cron[$name]
}
