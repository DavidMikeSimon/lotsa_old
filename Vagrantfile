Vagrant.configure(2) do |config|
  config.vm.define "werld"
  config.vm.hostname = "werld"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
    d.has_ssh = true
    d.name = "werld"
    d.remains_running = true
    d.create_args = ["--privileged"] # To allow fuse for sshfs
  end
  config.ssh.port = 22

  config.vm.synced_folder ".", "/vagrant", type: "sshfs"
end
