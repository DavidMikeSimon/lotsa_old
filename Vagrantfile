Vagrant.configure(2) do |config|
  config.vm.define "werld"
  config.vm.hostname = "werld"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
    d.has_ssh = true
    d.name = "werld"
    d.remains_running = true
  end
  config.ssh.port = 22

  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 3333, host: 3333
  config.vm.network "forwarded_port", guest: 9485, host: 9485
end
