
$config_mongodb_host = hiera('CONFIG_MONGODB_HOST_URL')

$config_ceilometer_coordination_backend = hiera('CONFIG_CEILOMETER_COORDINATION_BACKEND')

if $config_ceilometer_coordination_backend == 'redis' {
  $redis_ha = hiera('CONFIG_REDIS_HA')
  $redis_host = hiera('CONFIG_REDIS_MASTER_HOST_URL')
  $redis_port = hiera('CONFIG_REDIS_PORT')
  $sentinel_host = hiera('CONFIG_REDIS_SENTINEL_CONTACT_HOST')
  $sentinel_host_url = hiera('CONFIG_REDIS_SENTINEL_CONTACT_HOST_URL')
  $sentinel_fallbacks = hiera('CONFIG_REDIS_SENTINEL_FALLBACKS')
  if ($sentinel_host != '' and $redis_ha == 'y') {
    $master_name = hiera('CONFIG_REDIS_MASTER_NAME')
    $sentinel_port = hiera('CONFIG_REDIS_SENTINEL_PORT')
    $base_coordination_url = "redis://${sentinel_host_url}:${sentinel_port}?sentinel=${master_name}"
    if $sentinel_fallbacks != '' {
      $coordination_url = "${base_coordination_url}&${sentinel_fallbacks}"
    } else {
      $coordination_url = $base_coordination_url
    }
  } else {
    $coordination_url = "redis://${redis_host}:${redis_port}"
  }
} else {
  $coordination_url = ''
}

class { '::ceilometer::db':
  database_connection => "mongodb://${config_mongodb_host}:27017/ceilometer",
}

class { '::ceilometer::collector': }

class { '::ceilometer::agent::notification': }

class { '::ceilometer::agent::auth':
  auth_url      => hiera('CONFIG_KEYSTONE_PUBLIC_URL'),
  auth_password => hiera('CONFIG_CEILOMETER_KS_PW'),
  auth_region   => hiera('CONFIG_KEYSTONE_REGION'),
}

class { '::ceilometer::agent::central':
  coordination_url => $coordination_url,
}

class { '::ceilometer::alarm::notifier':}

class { '::ceilometer::alarm::evaluator':
  coordination_url => $coordination_url,
}

$bind_host = hiera('CONFIG_IP_VERSION') ? {
  'ipv6'  => '::0',
  default => '0.0.0.0',
  # TO-DO(mmagr): Add IPv6 support when hostnames are used
}
class { '::ceilometer::api':
  host                  => $bind_host,
  keystone_auth_uri     => hiera('CONFIG_KEYSTONE_PUBLIC_URL'),
  keystone_identity_uri => hiera('CONFIG_KEYSTONE_ADMIN_URL'),
  keystone_password     => hiera('CONFIG_CEILOMETER_KS_PW'),
}
