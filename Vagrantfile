# -*- mode: ruby -*-
# vi: set ft=ruby :

nodes_per_type = 2

vms = {
  'manager' => {
    'memory' => '2048', 
	'cpus' => 2,
	'ip' => 0, 
	'box' => 'geerlingguy/debian10', 
	'provision' => 'k8s_node_setup.sh'
  },
  'worker' => {
    'memory' => '1024',
    'cpus' => 2,
    'ip' => 50,
    'box' => 'geerlingguy/debian10',
	'provision' => 'k8s_node_setup.sh'		
  },
}

other_vms = {
  'load-balancer' => {
    'memory' => '256',
	'cpus' => 1,
    'ip' => 100,
    'box' => 'geerlingguy/debian10',
    'provision' => 'haproxy_setup.sh'

  },
} 

Vagrant.configure('2') do |config|

  config.vm.box_check_update = false
  
  (1..nodes_per_type).each do |i|
    vms.each do |name, conf|
	  config.vm.define "#{name}-0#{i}" do |my|
        my.vm.box = conf['box']
        my.vm.hostname = "#{name}-0#{i}"
        my.vm.network 'private_network', ip: "172.20.12.#{conf['ip'] + (10 * i)}"
        my.vm.provision 'shell', path: "provision/#{conf['provision']}"
		my.vm.provider 'virtualbox' do |vb|
		 vb.memory = conf['memory']
		 vb.name = "k8s_#{name}_0#{i}"
		 vb.cpus = conf['cpus']
		if "#{name}" == "manager-01"
		  my.vm.provision "file", source: "provision/files", destination: "/home/vagrant/files"
		end
		end
      end
    end
  end

  other_vms.each do |name, conf|
    config.vm.define "#{name}" do |my|
      my.vm.box = conf['box']
      my.vm.hostname = "#{name}"
      my.vm.network 'private_network', ip: "172.20.12.#{conf['ip']}"
     # my.vm.provision 'shell', path: "provision/#{conf['provision']}"
      my.vm.provider 'virtualbox' do |vb|
        vb.memory = conf['memory']
        vb.name = "k8s_#{name}"
        vb.cpus = conf['cpus']
	  end
    end
  end
end

