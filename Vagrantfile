Vagrant.configure(2) do |config|
  config.vm.define "chunkosm"
  config.vm.hostname = "chunkosm"
  config.vm.provider "docker" do |d|
    d.build_dir = "."
    d.has_ssh = true
    d.name = "chunkosm"
    d.remains_running = true
  end

  # Watch out for mix.lock, you need to manually copy it back if mix on guest updates it
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [
    ".git/", ".vagrant/", "*.swp", "*.swo", "*.build_time",
    "server/_build/", "server/deps/", "server/build_time",
    "webtest/node_modules/", "webtest/public/"
  ]
  config.ssh.port = 22

  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 3333, host: 3333
  config.vm.network "forwarded_port", guest: 9485, host: 9485

  config.gatling.rsync_on_startup = false

  config.exec.binstubs_path = 'vbin'
  config.exec.commands 'npm', directory: '/vagrant/webtest'
  config.exec.commands 'mix', directory: '/vagrant/server', env: { LC_ALL: 'en_US.UTF-8' }
end
