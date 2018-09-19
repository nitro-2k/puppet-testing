# Class: nitroworld::dns
#
# === Parameters
#
#
# === Examples
#
#  class {'nitro_config::dns':
#  ensure              => present,
#  dns1                   => 172.17.10.201,
#  dns2                   => 172.17.10.203,
#
# === Authors
#
# Andrew Petrie
#
# === Copyright
#
# Copyright 2018 Andrew Petrie.
#
class nitroworld::dns (
    $ensure = 'present',
    $dnsservers = undef,
    $dnssearch                   = ['UNSET'],
    $resolver_config_file        = '/etc/resolv-puppet.conf',
    $resolver_config_file_owner  = 'root',
    $resolver_config_file_group  = 'root',
    $resolver_config_file_mode   = '0644',
) {
  validate_re($ensure, '^(present|absent)$', 'valid values for ensure are \'present\' or \'absent\'')
  #validate_ip_address($dns1)
  #validate_ip_address($dns2)
  #validate_bool($installflag)

  if ($::operatingsystem == 'windows'){
    # Windows 2012 and newer required http://technet.microsoft.com/en-us/library/ee662309.aspx
    if $::kernelversion !~ /^(6\.2|6\.3|10\.0)/ { fail ("${module_name} requires Windows 2012 or newer") }

    if ($ensure == 'present') {
      exec { 'Update DNS':
        command   => template("nitroworld/dns.ps1.erb"),
        provider  => powershell,
      }
    }
  } elsif ($::operatingsystem == 'CentOS') {
    #Write some Linux DNS stuff :)
    # Validates domain
    #if is_domain_name($domain) != true {
    #  fail("Domain name, ${domain}, is invalid.")
    #}

    file { 'dnsclient_resolver_config_file':
      ensure  => file
      content => template('dnsclient/resolv.conf.erb'),
      path    => $resolver_config_file,
      owner   => $resolver_config_file_owner,
      group   => $resolver_config_file_group,
      mode    => $resolver_config_file_mode,
    }
  } else { fail ("${module_name} not supported on ${::operatingsystem}") }
}
