FROM phusion/baseimage:0.9.17

# Add elixir package source
RUN curl https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb > /tmp/erlang-solutions.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/erlang-solutions.deb

# Update packages
RUN apt-get update -q

# Enable and install SSH
RUN rm -f /etc/service/sshd/down
EXPOSE 22
RUN apt-get install -y openssh-server
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

# Install dev dependencies
RUN apt-get install -y elixir ruby nodejs npm entr tmux git
RUN ln -s nodejs /usr/bin/node
RUN gem install tmuxinator

# Clean up
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# phusion/baseimage init
CMD ["/sbin/my_init"]
