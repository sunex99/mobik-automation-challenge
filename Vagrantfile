Vagrant.configure("2") do |config|
  config.vm.define "k8s-vm"
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "k8s-vm"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/setup.yml"
    ansible.inventory_path = "ansible/hosts.ini"
    ansible.limit = "all"
  end
end
