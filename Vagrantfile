Vagrant.configure("2") do |config|
  config.vm.define "k8s-vm"
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "k8s-vm"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end

  # Sync project directory to VM
  config.vm.synced_folder "./app", "/home/vagrant/project"

  # Sync kubernetes directory to VM
  config.vm.synced_folder "./app", "/home/vagrant/project"
  config.vm.synced_folder "./kubernetes", "/home/vagrant/project/kubernetes"
  config.vm.synced_folder "./ansible", "/home/vagrant/project/ansible"

  # Provision with setup.yml
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/setup.yml"
    ansible.inventory_path = "ansible/hosts.ini"
    ansible.limit = "all"
  end

  # Provision with deploy-app.yml
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/deploy-app.yml"
    ansible.inventory_path = "ansible/hosts.ini"
    ansible.limit = "all"
  end
end