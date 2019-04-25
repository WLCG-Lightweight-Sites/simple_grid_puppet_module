# Run command 
# puppet apply --modulepath /etc/puppetlabs/code/environments/production/modules -e "class {'simple_grid::install::lightweight_component::simple_installer':puppet_master => 'basic_config_master.cern.ch'}"

class simple_grid::install::lightweight_component::simple_installer(  
  $puppet_master,
)
{
  notify{'Creating SIMPLE config directory':}
  class {'simple_grid::ccm_function::create_config_dir':}
  
  class{"simple_grid::components::ccm::installation_helper::init_agent":
    puppet_master => "${puppet_master}",
  }
  simple_grid::components::execution_stage_manager::set_stage {"Setting stage to install":
      simple_stage => lookup('simple_grid::stage::install')
  }
  
}
