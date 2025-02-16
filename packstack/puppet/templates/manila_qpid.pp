
$db_pw = hiera('CONFIG_MANILA_DB_PW')
$mariadb_host = hiera('CONFIG_MARIADB_HOST_URL')

class { '::manila':
  rpc_backend    => 'qpid',
  qpid_hostname  => hiera('CONFIG_AMQP_HOST_URL'),
  qpid_port      => hiera('CONFIG_AMQP_CLIENTS_PORT'),
  qpid_protocol  => hiera('CONFIG_AMQP_PROTOCOL'),
  qpid_username  => hiera('CONFIG_AMQP_AUTH_USER'),
  qpid_password  => hiera('CONFIG_AMQP_AUTH_PASSWORD'),
  sql_connection => "mysql://manila:${db_pw}@${mariadb_host}/manila",
  verbose        => true,
  debug          => hiera(CONFIG_DEBUG_MODE),
}
