include 'simple_grid::ccm_function::create_config_dir'

notify{"Installing git":}
package {"Install git":
  name   => 'git',
  ensure => present,
}

notify{"Installing External Node Classifier":}
class {'simple_grid::components::enc::install':}

notify{"Configuring External Node Classifier":}
class {'simple_grid::components::enc::configure':}

notify{"Creating a sample site level configuration file":}
class {"simple_grid::components::site_level_config_file::install":}

notify{"Installing Puppet CCM":}
class {"simple_grid::components::ccm::install":}

notify{"Configuring CCM on Config Master":}
class{"simple_grid::components::ccm::config":
  node_type => "CM"
}
