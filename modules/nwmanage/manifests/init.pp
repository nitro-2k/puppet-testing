class nwmanage (
	String $nw_key_file = "puppet:///modules/nwmanage/authorized_keys",
	String $nw_user = "nwmanage",
	String $nw_user_home = "/home/nwmanage",
) {

	user { "nwmanage":
		ensure => present,
		comment => "NW Management Account",
		home => "$nw_user_home",
		gid	=>	"10",
  }

	file { "${nw_user_home}":
		ensure => directory,
		mode   => "0755",
		owner  => "nwmanage",
		group	=> "wheel",
	}

	file { "${nw_user_home}/.ssh":
		ensure => directory,
		mode   => "0700",
		owner  => "nwmanage",
		group	=> "wheel",
	}

	file { "${nw_user_home}/.ssh/authorized_keys":
		ensure => file,
		mode   => "0600",
		source => "$nw_key_file",
		owner  => "nwmanage",
		group	=> "wheel",
	}
}
