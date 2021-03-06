# == Definition: mysql::rights
#
# A basic helper used to create a user and grant him some privileges on a database.
#
# Example usage:
#  percona::provision::rights { "example case":
#    user       => "foo",
#    password   => "bar",
#    database   => "mydata",
#    priv       => ["select_priv", "update_priv"],
#    sectret_id => 123456
#  }
#
#Available parameters:
#- *$ensure": defaults to present
#- *$database*: the target database
#- *$user*: the target user
#- *$password*: user's password
#- *$secret_id*: the ID for PIM
#- *$host*: target host, default to "localhost"
#- *$priv*: target privileges, defaults to "all" (values are the fieldnames from mysql.db table).

define percona::provision::rights(
  $database,
  $user,
  $password=undef,
  $secret_id=undef,
  $host='localhost',
  $ensure='present',
  $priv='all',
  $type='server'
) {

  if $::mysql_exists {
  if $type == 'server' {
    include percona::provision::service
    $real_service = "${::percona::provision::service::myservice}"
  }
  else
  {
    include percona::provision::service_cluster
    $real_service = "${::percona::provision::service_cluster::myservice}"
  }
    if $secret_id == undef and $password == undef {
      fail('You must privide a password or a secret_id to ::mysql::rights')
    }

    if $secret_id != undef {
      $mysql_password = getsecret($secret_id, 'Password')
    } else {
      $mysql_password = $password
    }

    ensure_resource('percona_user', "${user}@${host}", {
      ensure        => $ensure,
      password_hash => mysql_password($mysql_password),
      provider      => 'mysql',
      require       => Service["${real_service}"]
    })

    if $ensure == 'present' {
      mysql_grant { "${user}@${host}/${database}":
        privileges => $priv,
        provider   => 'mysql',
        require    => [ Percona_user["${user}@${host}"], Service["${real_service}"] ]
      }
    }

    if $ensure == 'absent' {
      percona_user { "${user}@${host}":
        ensure => absent
      }
    }
  } else {
    fail("Mysql binary not found, Fact[::mysql_exists]:${::mysql_exists}")
  }
}
