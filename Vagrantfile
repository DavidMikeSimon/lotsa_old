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
  config.gatling.rsync_on_startup = false

  # Watch out for mix.lock, you need to manually copy it back if mix on guest updates it
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [
    ".git/", ".vagrant/", "*.swp", "*.swo",
    "_build/", "deps/",
    "webtest/node_modules/", "webtest/public/"
  ]
end
