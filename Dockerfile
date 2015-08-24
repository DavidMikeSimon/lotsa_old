FROM phusion/baseimage:0.9.17

# Add elixir package source

RUN curl https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb > /tmp/erlang-solutions.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/erlang-solutions.deb

# Install packages

RUN apt-get update -q && apt-get install -y \
	elixir \
	erlang-nox \
	nodejs \
	npm \
	git \
	unzip \
	entr \
	openssh-server
RUN ln -s nodejs /usr/bin/node

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

# Install erlang parsetools yecc files needed by exprotoc

RUN curl -L https://github.com/otphub/parsetools/archive/OTP-18.0.zip > /tmp/parsetools.zip
RUN unzip -j /tmp/parsetools.zip  'parsetools-OTP-18.0/include/*' -d /usr/lib/erlang/lib/parsetools-2.1/include

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies and set up build directories

RUN mkdir /tmp/vagrant
RUN chown vagrant:vagrant /tmp/vagrant

WORKDIR /tmp/vagrant
USER vagrant

RUN mkdir node_modules
COPY webtest/package.json /tmp/vagrant/
RUN npm install
RUN rm package.json

RUN mkdir bower_components
COPY webtest/bower.json /tmp/vagrant/
RUN yes | ./node_modules/.bin/bower install
RUN rm bower.json

COPY mix.* /tmp/vagrant/
RUN yes | mix deps.get
RUN yes | mix deps.compile
RUN rm mix.*

# phusion/baseimage init

WORKDIR /
USER root
CMD ["/sbin/my_init"]
