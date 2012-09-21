# == Class: riak::config

# Doing some fun stuff such as setting up the repositories
# in the case of centos / rhel, this assumes you haven't installed
# the basho-release-*.rpm.
# there is a bug in our debian startup script -- it doesn't have
# a "status" parameter, yet.  Working around that for now.

class riak::config( 
	$absent = false,
        $manage_repos = true
) {

  $package_repo_type = $::operatingsystem ? {
    /(?i:centos|redhat)/ => 'yum',
    /(?i:debian|ubuntu)/ => 'apt'
  }


  $manage_yum_repo = $absent ? {
    true    => 'absent',
    default => '1'
  }

  $manage_apt_repo = $absent ? {
    true    => 'absent',
    default => 'present'
  }

  if $manage_repos == true {
	case $package_repo_type {
    'apt': {
        file { 
          'apt-basho':
            path    => '/etc/apt/sources.list.d/basho.list',
            content => "deb http://apt.basho.com ${lsbdistcodename} main\n",
        	ensure  => $manage_apt_repo
         }
         package { 
         	'curl' : ensure => installed 
         }
         exec {
          'add-basho-key':
            command  => '/usr/bin/curl http://apt.basho.com/gpg/basho.apt.key | /usr/bin/apt-key add -',
            unless   => '/usr/bin/apt-key list | /bin/grep -q "Basho Technologies"',
            require  => [ Package['curl']]
         }
         exec {
          'apt-get-update':
            command     => '/usr/bin/apt-get update',
            subscribe   => File['apt-basho'],
            refreshonly => true
         }         
	     }
     'yum': {
       	yumrepo {
  			'basho-products':
  			  descr 	=> "basho packages for \$releasever-\$basearch",
  			  baseurl 	=> "http://yum.basho.com/el/6/products/\$basearch",
  			  gpgcheck 	=> 1,
  			  enabled 	=> $manage_yum_repo,
  			  gpgkey 	=> "http://yum.basho.com/gpg/RPM-GPG-KEY-basho"				  
       	}	     	
	     }
    }
  }
}     
