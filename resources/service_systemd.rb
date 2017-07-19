provides :nexus3_service_systemd

provides :nexus3_service, os: 'linux' do |_node|
  Chef::Platform::ServiceHelpers.service_resource_providers.include?(:systemd)
end

property :instance_name, String, name_property: true
property :install_dir, String
property :nexus3_user, String
property :nexus3_group, String

action :start do
  create_init

  service "nexus3_#{new_resource.instance_name}" do
    provider Chef::Provider::Service::Systemd
    supports restart: true, status: true
    action :start
    only_if 'command -v java >/dev/null 2>&1 || exit 1'
  end
end

action :stop do
  service "nexus3_#{new_resource.instance_name}" do
    provider Chef::Provider::Service::Systemd
    supports status: true
    action :stop
    only_if { ::File.exist?("/etc/systemd/system/nexus3_#{new_resource.instance_name}.service") }
  end
end

action :restart do
  service "nexus3_#{new_resource.instance_name}" do
    provider Chef::Provider::Service::Systemd
    supports status: true
    action :restart
  end
end

action :disable do
  service "nexus3_#{new_resource.instance_name}" do
    provider Chef::Provider::Service::Systemd
    supports status: true
    action :disable
    only_if { ::File.exist?("/etc/systemd/system/nexus3_#{new_resource.instance_name}.service") }
  end
end

action :enable do
  create_init

  service "nexus3_#{new_resource.instance_name}" do
    provider Chef::Provider::Service::Systemd
    supports status: true
    action :enable
    only_if { ::File.exist?("/etc/systemd/system/nexus3_#{new_resource.instance_name}.service") }
  end
end

action_class do
  def create_init
    template "/etc/systemd/system/nexus3_#{new_resource.instance_name}.service" do
      source 'init_systemd.erb'
      variables(
        instance_name: new_resource.instance_name,
        install_dir: new_resource.install_dir,
        nexus3_user: new_resource.nexus3_user
      )
      owner new_resource.nexus3_user
      group new_resource.nexus3_group
      mode '0644'
      cookbook 'nexus3'
      notifies :run, 'execute[Load systemd unit file]', :immediately
      notifies :restart, "service[nexus3_#{new_resource.instance_name}]"
    end

    execute 'Load systemd unit file' do
      command 'systemctl daemon-reload'
      action :nothing
    end
  end
end