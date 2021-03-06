class simple_grid::components::component_repository::deploy_step_1(
  $execution_id,
  $timestamp,
  $augmented_site_level_config_file = lookup('simple_grid::components::yaml_compiler::output'),
  $deploy_status_file = lookup('simple_grid::nodes::lightweight_component::deploy_status_file'),
  $component_repository_dir = lookup('simple_grid::nodes::lightweight_component::component_repository_dir'),
  $meta_info_prefix = lookup('simple_grid::components::site_level_config_file::objects:meta_info_prefix'),
  $simple_grid_scripts_dir = lookup('simple_grid::scripts_dir')
){
  $data = loadyaml($augmented_site_level_config_file)
  $current_lightweight_component = simple_grid::get_lightweight_component($augmented_site_level_config_file, $execution_id)
  $repository_name = $current_lightweight_component['name']
  $meta_info_parent = "${meta_info_prefix}${downcase($repository_name)}"
  $meta_info = $data["${meta_info_parent}"]
  $repository_path = "${component_repository_dir}/${repository_name}_${execution_id}"
  $dns_info = simple_grid::get_dns_info($data, $execution_id)
  $scripts_dir_structure = simple_grid::generate_lifecycle_script_directory_structure($augmented_site_level_config_file, $simple_grid_scripts_dir)
  $pre_config_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'pre_config')
  $pre_init_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'pre_init')
  $post_init_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'post_init')
  notify{"Deploy Stage Step 1 -  execution_id ${execution_id} with name ${repository_name} now!!!!":}
  Class['simple_grid::ccm_function::prep_host'] ->
  Class['simple_grid::component::component_repository::lifecycle::hook::pre_config'] ->
  Class['simple_grid::component::component_repository::lifecycle::event::pre_config'] ->
  Class['simple_grid::component::component_repository::lifecycle::event::boot']

  class{'simple_grid::ccm_function::prep_host':
    current_lightweight_component => $current_lightweight_component,
    meta_info                     => $meta_info,
  }

  class{'simple_grid::component::component_repository::lifecycle::hook::pre_config':
    scripts      => $pre_config_scripts,
    execution_id => $execution_id,
    timestamp    => $timestamp
  }

  class{'simple_grid::component::component_repository::lifecycle::event::pre_config':
      current_lightweight_component => $current_lightweight_component,
      execution_id                  => $execution_id,
  }
  class{'simple_grid::component::component_repository::lifecycle::event::boot':
      current_lightweight_component => $current_lightweight_component,
      execution_id => $execution_id, 
      meta_info    => $meta_info,
  }
  simple_grid::components::execution_stage_manager::set_stage {'Setting stage to deploy_step_2':
    simple_stage => lookup('simple_grid::stage::deploy::step_2')
    }
}

class simple_grid::components::component_repository::deploy_step_2(
  $execution_id,
  $timestamp,
  $augmented_site_level_config_file = lookup('simple_grid::components::yaml_compiler::output'),
  $deploy_status_file = lookup('simple_grid::nodes::lightweight_component::deploy_status_file'),
  $component_repository_dir = lookup('simple_grid::nodes::lightweight_component::component_repository_dir'),
  $meta_info_prefix = lookup('simple_grid::components::site_level_config_file::objects:meta_info_prefix'),
  $simple_grid_scripts_dir = lookup('simple_grid::scripts_dir'),
  $data = loadyaml($augmented_site_level_config_file)
){
  $current_lightweight_component = simple_grid::get_lightweight_component($augmented_site_level_config_file, $execution_id)
  $repository_name = $current_lightweight_component['name']
  $meta_info_parent = "${meta_info_prefix}${downcase($repository_name)}"
  $meta_info = $data["${meta_info_parent}"]
  $repository_path = "${component_repository_dir}/${repository_name}_${execution_id}"
  $dns_info = simple_grid::get_dns_info($data, $execution_id)
  $scripts_dir_structure = simple_grid::generate_lifecycle_script_directory_structure($augmented_site_level_config_file, $simple_grid_scripts_dir)
  $pre_config_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'pre_config')
  $pre_init_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'pre_init')
  $post_init_scripts = simple_grid::get_scripts($scripts_dir_structure, $execution_id, 'post_init')
  notify{"Deploy Stage Step 2 -  execution_id ${execution_id} with name ${repository_name} now!!!!":}
  Class['simple_grid::component::component_repository::lifecycle::hook::pre_init'] ->
  Class['simple_grid::component::component_repository::lifecycle::event::init'] ->
  Class['simple_grid::component::component_repository::lifecycle::hook::post_init']

  class{"simple_grid::component::component_repository::lifecycle::hook::pre_init":
    scripts   => $pre_init_scripts,
    timestamp => $timestamp,
    current_lightweight_component => $current_lightweight_component,
    execution_id => $execution_id,
    container_name => $dns_info['container_fqdn']
  }
  class{"simple_grid::component::component_repository::lifecycle::event::init":
    current_lightweight_component => $current_lightweight_component,
    execution_id => $execution_id,
    timestamp    => $timestamp,
    container_name => $dns_info['container_fqdn'],
  }
  class{"simple_grid::component::component_repository::lifecycle::hook::post_init":
    scripts => $post_init_scripts,
    current_lightweight_component => $current_lightweight_component,
    execution_id => $execution_id,
    timestamp   => $timestamp,
    container_name => $dns_info['container_fqdn']
  }
  simple_grid::components::execution_stage_manager::set_stage {'Setting stage to final':
    simple_stage => lookup('simple_grid::stage::final')
    }
}

class simple_grid::components::component_repository::rollback(
  $execution_id,
  $remove_images,
  $component_image_tag = lookup('simple_grid::components::component_repository::component_image_tag'),
  $pre_config_image_tag = lookup('simple_grid::components::component_repository::pre_config_image_tag'),
  $meta_info_prefix = lookup('simple_grid::components::site_level_config_file::objects:meta_info_prefix'),
  $augmented_site_level_config_file = lookup('simple_grid::components::yaml_compiler::output'),
  $deploy_status_file = lookup('simple_grid::nodes::lightweight_component::deploy_status_file'),
  $pending_deploy_status = lookup('simple_grid::stage::deploy::status::initial')
){
  $augmented_site_level_config = loadyaml($augmented_site_level_config_file)
  $dns = simple_grid::get_dns_info($augmented_site_level_config, $execution_id)
  $container_name = $dns['container_fqdn']
  $docker_stop_rm_command = "docker stop ${container_name} && docker rm ${container_name}"
  exec{"Cleanup container ${container_name}":
    command     => $docker_stop_rm_command,
    user        => root,
    logoutput   => true,
    path        => '/usr/sue/sbin:/usr/sue/bin:/use/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin:/bin:/opt/puppetlabs/bin',
    environment => ['HOME=/root']
  }
  if $remove_images {
    $current_lightweight_component = simple_grid::get_lightweight_component($augmented_site_level_config_file, $execution_id)
    $level_2_configurator = simple_grid::get_level_2_configurator($augmented_site_level_config, $current_lightweight_component)
    $repository_name = $current_lightweight_component['name']
    $meta_info_parent = "${meta_info_prefix}${downcase($repository_name)}"
    $meta_info = $augmented_site_level_config["${meta_info_parent}"]
    $repository_name_lowercase = downcase($repository_name)
    $pre_config_image_name = "${repository_name_lowercase}_${pre_config_image_tag}"
    if has_key($meta_info['level_2_configurators']["${level_2_configurator}"], 'docker_hub_tag'){
        $docker_hub_tag = $meta_info['level_2_configurators']["${level_2_configurator}"]['docker_hub_tag']
    }else {
        $docker_hub_tag = ''
    }
    if length($docker_hub_tag)> 0 {
      $image_name = $docker_hub_tag
    }else {
      $image_name = "${repository_name_lowercase}_${component_image_tag}"
    }
    # notify{"****** Removing ****** : ${image_name} ${pre_config_image_name}":}
    exec{"Removing boot image: ${image_name}":
      command     => "docker rmi ${image_name}",
      user        => root,
      logoutput   => true,
      path        => '/usr/sue/sbin:/usr/sue/bin:/use/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin:/bin:/opt/puppetlabs/bin',
      environment => ['HOME=/root']
    }
    exec{"Removing pre_config image: ${pre_config_image_name}":
      command     => "docker rmi ${pre_config_image_name}",
      user        => root,
      logoutput   => true,
      path        => '/usr/sue/sbin:/usr/sue/bin:/use/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin:/bin:/opt/puppetlabs/bin',
      environment => ['HOME=/root']
    }
  }
  simple_grid::set_execution_status($deploy_status_file, $execution_id, $pending_deploy_status)
  simple_grid::components::execution_stage_manager::set_stage {'Setting stage to deploy_step_1':
    simple_stage => lookup('simple_grid::stage::deploy::step_1')
    }
}

class simple_grid::component::component_repository::lifecycle::hook::pre_config(
  $scripts,
  $execution_id,
  $timestamp,
  $log_flag = 'pre_config::hook',
  $script_wrapper_dir = lookup('simple_grid::scripts::wrapper_dir'),
  $log_dir = lookup('simple_grid::simple_log_dir'),
  $lifecycle_wrapper = lookup('simple_grid::scripts::wrapper::lifecycle'),
  $retry_wrapper = lookup('simple_grid::scripts::wrapper::retry'),
  $mode = lookup('simple_grid::mode'),
){
  $scripts.each |Hash $script|{
    $actual_script = $script['actual_script']
    notify{"Running pre config script ${actual_script}. The output is available at ${log_dir}/${execution_id}/${timestamp}":}
    $command = "${script_wrapper_dir}/${retry_wrapper} --command=\"${script_wrapper_dir}/${lifecycle_wrapper} ${actual_script} ${log_dir}/${execution_id}/${timestamp} pre_config\" --recovery-command=\"sleep 5\" --flag='${log_flag}'"
    notify{"Running command: ${command}":}
    if $mode == lookup('simple_grid::mode::docker') or $mode == lookup('simple_grid::mode::dev') {
      exec{"Executing Pre-Config Script ${script}":
        command     => $command,
        path        => '/usr/sue/sbin:/usr/sue/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin',
        user        => 'root',
        logoutput   => true,
        environment => ['HOME=/root'],
        timeout     => 0,
        provider    => shell
      }
    }
    elsif $mode == lookup('simple_grid::mode::release') {
      exec{"Executing Pre-Config Script ${script}":
        command     => "${script_wrapper_dir}/${retry_wrapper} --command=\"${script_wrapper_dir}/${lifecycle_wrapper} ${actual_script} ${log_dir}/${execution_id}/${timestamp} pre_config\" --recovery-command=\"sleep 5\" --flag='${log_flag}'",
        path        => '/usr/sue/sbin:/usr/sue/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin',
        user        => 'root',
        logoutput   => true,
        timeout     => 0,
        provider    => shell
      }
    }
  }
}

class simple_grid::component::component_repository::lifecycle::event::pre_config(
  $current_lightweight_component,
  $execution_id,
  $component_repository_dir = lookup('simple_grid::nodes::lightweight_component::component_repository_dir'),
  $augmented_site_level_config_file = lookup('simple_grid::components::yaml_compiler::output'),
  $mode = lookup("simple_grid::mode"),
  $pre_config_image_tag = lookup('simple_grid::components::component_repository::pre_config_image_tag'),
  $l2_relative_config_dir = lookup('simple_grid::components::component_repository::l2_relative_config_dir'),
  $l2_relative_pre_config_dir = lookup('simple_grid::components::component_repository::l2_relative_pre_config_dir'),
)
{
  $augmented_site_level_config = loadyaml("${augmented_site_level_config_file}")
  $repository_name = $current_lightweight_component['name']
  $repository_path = "${component_repository_dir}/${repository_name}_${execution_id}"
  $level_2_configurator = simple_grid::get_level_2_configurator($augmented_site_level_config, $current_lightweight_component)
  $pre_config_dir = "${repository_path}/${level_2_configurator}/${l2_relative_pre_config_dir}"
  $config_dir = "${repository_path}/${level_2_configurator}/${l2_relative_config_dir}/"
  $repository_name_lowercase = downcase($repository_name)
  $pre_config_image_name = "${repository_name_lowercase}_${pre_config_image_tag}"
  $docker_run_command = "docker run --rm -i -v ${repository_path}:/component_repository -e 'EXECUTION_ID=${execution_id}' ${pre_config_image_name}"
  notify{"Building Dockerfile at: ${pre_config_dir}":}
  Simple_grid::Components::Docker::Build_image['Build pre_config image'] -> Simple_grid::Components::Docker::Run['Executing pre_config container']
  file{"Create ${config_dir}":
    ensure => directory,
    path   => $config_dir,
    mode   => '0766',
  }
  simple_grid::components::docker::build_image { 'Build pre_config image':
    image_name => $pre_config_image_name,
    dockerfile => $pre_config_dir,
    log_flag   => 'pre_config::event::docker::build_image',
  }
  simple_grid::components::docker::run{'Executing pre_config container':
    command               => $docker_run_command,
    log_flag              => 'pre_config::event::docker::run',
    container_description => "Pre-Config container for ${repository_name} with execution id: ${execution_id}"
  }
}

class simple_grid::component::component_repository::lifecycle::event::boot(
  $current_lightweight_component,
  $execution_id,
  $meta_info,
  ## Host directories ##
  $component_repository_dir = lookup('simple_grid::nodes::lightweight_component::component_repository_dir'),
  $augmented_site_level_config_file = lookup('simple_grid::components::yaml_compiler::output'),
  $scripts_dir = lookup('simple_grid::scripts_dir'),
  $wrapper_dir = lookup('simple_grid::scripts::wrapper_dir'),
  ## params for Container Bootup ###
  $network = lookup('simple_grid::components::swarm::network'),
  $component_image_tag = lookup('simple_grid::components::component_repository::component_image_tag'),
  ## Component Repository Directory Structure ##
  $repository_relative_host_certificates_dir = lookup('simple_grid::components::component_repository::relative_host_certificates_dir'),
  $l2_repository_relative_config_dir = lookup('simple_grid::components::component_repository::l2_relative_config_dir'),
  ### Container Directory Structure ###
  $container_scripts_dir = lookup('simple_grid::components::component_repository::container::scripts_dir'),
  $container_script_wrappers_dir = lookup('simple_grid::components::component_repository::container::script_dir::wrappers'),
  $container_host_certificates_dir = lookup('simple_grid::components::component_repository::container::host_certificates_dir'),
  $container_augmented_site_level_config_file = lookup('simple_grid::components::component_repository::container::augmented_site_level_config_file'),
  $container_config_dir = lookup('simple_grid::components::component_repository::container::config_dir'),
  $log_dir = lookup('simple_grid::simple_log_dir')
){
  $augmented_site_level_config = loadyaml($augmented_site_level_config_file)
  $level_2_configurator = simple_grid::get_level_2_configurator($augmented_site_level_config, $current_lightweight_component)
  $repository_name = $current_lightweight_component['name']
  $repository_path = "${component_repository_dir}/${repository_name}_${execution_id}"
  $config_dir = "${repository_path}/${level_2_configurator}/${l2_repository_relative_config_dir}"
  $logs_dir = "${log_dir}/${execution_id}"
  $container_logs_dir = "${log_dir}"
  if has_key($meta_info['level_2_configurators']["${level_2_configurator}"], 'docker_hub_tag'){
    $docker_hub_tag = $meta_info['level_2_configurators']["${level_2_configurator}"]['docker_hub_tag']
  } else {
      $docker_hub_tag = ''
  }
  if length($docker_hub_tag)> 0 {
    $image_name = $docker_hub_tag
    simple_grid::components::docker::pull_image{"Fetching ${image_name} from image registry":
      image_name => $image_name
    }
  }else {
    $repository_name_lowercase = downcase($repository_name)
    $image_name = "${repository_name_lowercase}_${component_image_tag}"
    notify{"Building boot image: ${image_name}":}
    simple_grid::components::docker::build_image{'Build boot Image':
      image_name => $image_name,
      dockerfile => "${repository_path}/${level_2_configurator}",
      log_flag   => 'boot::event::docker::build_image',
      before     => Simple_grid::Components::Docker::Run['Start boot container'],
    }
  }
  $host_certificates_dir = "${repository_path}/${repository_relative_host_certificates_dir}"
  $docker_run_command = simple_grid::docker_run(
    $augmented_site_level_config,
    $current_lightweight_component,
    $meta_info,
    $image_name,
    $augmented_site_level_config_file,
    $container_augmented_site_level_config_file,
    $config_dir,
    $container_config_dir,
    $scripts_dir,
    $container_scripts_dir,
    $wrapper_dir,
    $container_script_wrappers_dir,
    $logs_dir,
    $container_logs_dir,
    $host_certificates_dir,
    $container_host_certificates_dir,
    $network,
    $level_2_configurator
  )
  notify{"Docker run command\n ${docker_run_command}":}
  simple_grid::components::docker::run { 'Start boot container':
    command               => $docker_run_command,
    log_flag              => 'boot::event::docker::run',
    container_description => "Container for ${repository_name} with Execution ID: ${execution_id}"
  }
}

class simple_grid::component::component_repository::lifecycle::hook::pre_init(
  $current_lightweight_component,
  $execution_id,
  $timestamp,
  $scripts,
  $container_name,
  $lifecycle_wrapper = lookup('simple_grid::scripts::wrapper::lifecycle'),
  $log_dir = lookup('simple_grid::simple_log_dir'),
  $pre_init_hook = lookup('simple_grid::components::component_repository::lifecycle::hook::pre_init'),
  $container_scripts_dir = lookup('simple_grid::components::component_repository::container::scripts_dir'),
  $container_script_wrappers_dir = lookup('simple_grid::components::component_repository::container::script_dir::wrappers'),
){
  $scripts.each |Hash $script|{
    $script_name = split($script['actual_script'], '/')[-1]
    $script_path = "${container_scripts_dir}/${pre_init_hook}/${script_name}"
    $command = "${container_script_wrappers_dir}/${lifecycle_wrapper} ${script_path} ${log_dir}/${timestamp} pre_init"
    notify{"Executing pre_init hook ${command}. The output is available at ${log_dir}/${execution_id}/${timestamp}":}
    simple_grid::components::docker::exec{"Running pre_init hook ${script_path} for Execution ID ${execution_id}":
      container_name => $container_name,
      log_flag       => 'pre_init::hook::docker::exec',
      command        => $command
    }
    # exec{"Running pre_init hook ${script_path} for Execution ID ${execution_id}":
    #   command => $command,
    #   path    => "/usr/local/bin:/usr/bin/:/bin:/opt/puppetlabs/bin",
    #   user    => "root",
    #   logoutput => true,
    #   environment => ['HOME=/root']
    # }
  }
}
class simple_grid::component::component_repository::lifecycle::event::init(
  $current_lightweight_component,
  $execution_id,
  $timestamp,
  $container_name,
  $lifecycle_wrapper = lookup('simple_grid::scripts::wrapper::lifecycle'),
  $log_dir = lookup('simple_grid::simple_log_dir'),
  $config_dir = lookup('simple_grid::components::component_repository::container::config_dir'),
  $container_scripts_dir = lookup('simple_grid::components::component_repository::container::scripts_dir'),
  $container_script_wrappers_dir = lookup('simple_grid::components::component_repository::container::script_dir::wrappers'),
){
  $command = "${container_script_wrappers_dir}/${lifecycle_wrapper} ${config_dir}/init.sh ${log_dir}/${timestamp} init"
  notify{"Executing init event : ${command}. The logs will be available at: ${log_dir}/${execution_id}/${timestamp}":}
  simple_grid::components::docker::exec{"Running init event for Execution ID ${execution_id}":
    container_name => $container_name,
    log_flag       => 'init::event::docker::exec',
    command        => $command 
  }
  # exec{"Running init event for Execution ID ${execution_id}":
  #     command => $command,
  #     path    => "/usr/local/bin:/usr/bin/:/bin:/opt/puppetlabs/bin",
  #     user    => "root",
  #     environment => ['HOME=/root'],
  #     provider => 'shell',
  # }
}

class simple_grid::component::component_repository::lifecycle::hook::post_init(
  $current_lightweight_component,
  $execution_id,
  $scripts,
  $container_name,
  $timestamp,
  $lifecycle_wrapper = lookup('simple_grid::scripts::wrapper::lifecycle'),
  $log_dir = lookup('simple_grid::simple_log_dir'),
  $post_init_hook = lookup('simple_grid::components::component_repository::lifecycle::hook::post_init'),
  $container_scripts_dir = lookup('simple_grid::components::component_repository::container::scripts_dir'),
  $container_script_wrappers_dir = lookup('simple_grid::components::component_repository::container::script_dir::wrappers'),
){
  $scripts.each |Hash $script|{
    $script_name = split($script['actual_script'], '/')[-1]
    $script_path = "${container_scripts_dir}/${post_init_hook}/${script_name}"
    $command = "${container_script_wrappers_dir}/${lifecycle_wrapper} ${script_path} ${log_dir}/${timestamp} post_init"
    notify{"Executing post_init hook ${command}. The logs will be available at ${log_dir}/${execution_id}/${timestamp}":}
    simple_grid::components::docker::exec{ "Running post_init hook ${script_path} for Execution ID ${execution_id} with script":
      container_name => $container_name,
      log_flag       => 'post_init::hook::docker::exec',
      command        => $command
    }
    # exec{"":
    #   command => $command,
    #   path    => "/usr/local/bin:/usr/bin/:/bin:/opt/puppetlabs/bin",
    #   user    => "root",
    #   environment => ['HOME=/root']
    # }
  }
}
