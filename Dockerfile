FROM phusion/baseimage:0.9.17

# Add package sources

RUN curl https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb > /tmp/erlang-solutions.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/erlang-solutions.deb
RUN rm /tmp/erlang-solutions.deb
RUN sed -i=orig 's/http:\/\/binaries/https:\/\/apt-mirror.openstack.blueboxgrid.com\/packages/' /etc/apt/sources.list.d/erlang-solutions.list

RUN apt-add-repository -y ppa:brightbox/ruby-ng

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 68576280
RUN apt-add-repository 'deb https://deb.nodesource.com/node_4.x precise main'

# Install packages

RUN apt-get update -q
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y erlang-nox
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y erlang-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y elixir
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ruby2.3
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ruby2.3-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y rsync

RUN gem install rb-inotify rerun

# Enable SSH

RUN rm -f /etc/service/sshd/down
EXPOSE 22
RUN mkdir -p /var/run/sshd
RUN chmod 0755 /var/run/sshd

# Create and configure vagrant user

RUN useradd --create-home -s /bin/bash vagrant
RUN mkdir -p /home/vagrant/.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /home/vagrant/.ssh/authorized_keys
RUN chown -R vagrant: /home/vagrant/.ssh
RUN echo -n 'vagrant:vagrant' | chpasswd
RUN mkdir -p /etc/sudoers.d
RUN install -b -m 0440 /dev/null /etc/sudoers.d/vagrant
RUN echo 'vagrant ALL=NOPASSWD: ALL' >> /etc/sudoers.d/vagrant

RUN echo '' >> /home/vagrant/.bashrc
RUN echo 'export LANG=en_US.utf-8' >> /home/vagrant/.bashrc
RUN echo 'export LC_ALL=en_US.utf-8' >> /home/vagrant/.bashrc
RUN echo 'cd /vagrant' >> /home/vagrant/.bashrc

# Fix locale problem for Erlang

RUN update-locale LC_ALL=en_US.UTF-8

# Install dependencies

RUN mkdir -p /vagrant/server
RUN mkdir -p /vagrant/webtest
COPY server/mix.exs /vagrant/server
COPY server/mix.lock /vagrant/server
COPY webtest/package.json /vagrant/webtest
RUN chown -R vagrant:vagrant /vagrant

USER vagrant

WORKDIR /vagrant/server
RUN LC_ALL=en_US.UTF-8 mix local.hex --force
RUN LC_ALL=en_US.UTF-8 mix local.rebar --force
RUN LC_ALL=en_US.UTF-8 mix deps.get
RUN LC_ALL=en_US.UTF-8 mix deps.compile

WORKDIR /vagrant/webtest
RUN npm install

USER root
RUN chown -R vagrant:vagrant /vagrant

# Set up runit services for server and webtest

RUN mkdir -p /etc/service/werld-server/supervise
RUN echo "#!/bin/sh" > /etc/service/werld-server/run
RUN echo "set -e" >> /etc/service/werld-server/run
RUN echo "test -e /vagrant/server/lib || exit 1" >> /etc/service/werld-server/run
RUN echo "su vagrant -c \"cd /vagrant/server && rerun -b -d 'lib,test,../proto' -p '**/*.{ex,exs,proto}' --name werld -- elixir --sname werld -S mix run --no-halt 2>&1 | logger -i -t werld-server\"" >> /etc/service/werld-server/run
RUN chmod a+x /etc/service/werld-server/run
RUN chown -R root:root /etc/service/werld-server

RUN mkdir -p /etc/service/werld-webtest/supervise
RUN echo "#!/bin/sh" > /etc/service/werld-webtest/run
RUN echo "test -e /vagrant/webtest/app || exit 1" >> /etc/service/werld-webtest/run
RUN echo "su vagrant -c \"cd /vagrant/webtest && ./node_modules/brunch/bin/brunch watch --server 2>&1 | logger -i -t werld-webtest\"" >> /etc/service/werld-webtest/run
RUN echo "set -e" >> /etc/service/werld-webtest/run
RUN chmod a+x /etc/service/werld-webtest/run
RUN chown -R root:root /etc/service/werld-webtest

# phusion/baseimage init

WORKDIR /
CMD ["/sbin/my_init"]
