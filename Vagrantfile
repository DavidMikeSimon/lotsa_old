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
end
