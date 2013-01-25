# Class: jenkins::slave
#
#
#  ensure is not immplemented yet, since i'm assuming you want to actually run the slave by declaring it..
#
class jenkins::slave (
  $masterurl = undef,
  $ui_user = undef,
  $ui_pass = undef,
  $version = '1.8',
  $executors = 2,
  $manage_slave_user = 1,
  $slave_user = 'jenkins_slave',
  $slave_uid = undef,
  $slave_home = undef,
  )
  {
  
  $client_jar = "swarm-client-$version-jar-with-dependencies.jar"
  $client_url = "http://maven.jenkins-ci.org/content/repositories/releases/org/jenkins-ci/plugins/swarm-client/$version/"
  
  
  case $::osfamily {
    'RedHat': {
      $java_package = 'java-1.6.0-openjdk'
    }
    'Debian': {
      #needs java package for debian.
     fail( "Unsupported OS family: ${::osfamily}" )
  #    $java_package=''

    }

    default: {
      fail( "Unsupported OS family: ${::osfamily}" )
    }
  }

  
  

	#add jenkins slave if necessary.
  
  if $manage_slave_user == 1 {
    user { "jenkins-slave_user":
      name => "$slave_user",
      comment => "Jenkins Slave user",
  		home => "$slave_home",
  		ensure => present,
  		managehome => true,
      uid => "$slave_uid"
  	}
  }  
   
   
  package {   
    "$java_package" :
    ensure => installed;
  }

  exec { 'get_swarm_client':
    command => "wget -O $slave_home/$client_jar $client_url ",
    path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    user => 'jenkins-slave',
    #refreshonly => true,
    creates => "$slave_home/$client_jar"
    ## needs to be fixed if you create another version..
  }
  
  
  
  if $ui_user { 
    $ui_user_flag = "-username $ui_user" 
  }
  
  if $ui_pass { 
    $ui_pass_flag = "-password $ui_pass" 
  }
  
  if $masterurl { 
    $masterurl_flag = "-master $masterurl" 
  }
  
  exec { 'run_swarm_client':
    command => "java -jar $slave_home/$client_jar  $ui_user_flag  $ui_pass_flag  -name $fqdn -executors $executors $masterurl_flag &",
    path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    user => 'jenkins-slave',
    #refreshonly => true,
    onlyif => "pgrep -f -u jenkins-slave $client_jar",
    ## needs to be fixed if you create another version..
  }
 
  
  Package["$java_package"] -> Exec['get_swarm_client'] -> Exec['run_swarm_client']
  
}