#
# Cookbook Name:: mail.slimta.org
# Recipe:: mailserver
#
# Copyright 2014, Ian Good
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

service 'dovecot' do
   supports :restart => true, :status => true
   action :nothing
end

directory '/var/mail' do
  mode 02775
  owner 'root'
  group 'mail'
end

[
  'dovecot-imapd',
  'dovecot-sieve',
  'dovecot-managesieved',
  'dovecot-lmtpd'
].each do |pkg|
  package pkg do
    action :install
    notifies :restart, 'service[dovecot]'
  end
end

template '/etc/dovecot/conf.d/10-auth.conf' do
  source 'dovecot/10-auth.conf.erb'
  mode 00644
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/10-mail.conf' do
  source 'dovecot/10-mail.conf.erb'
  mode 00644
  variables({
    :mail_root => '/var/mail',
  })
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/10-master.conf' do
  source 'dovecot/10-master.conf.erb'
  mode 00644
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/10-ssl.conf' do
  source 'dovecot/10-ssl.conf.erb'
  mode 00644
  variables({
    :cert_file => '/etc/slimta/certs/cert.pem',
    :key_file => '/etc/slimta/certs/key.pem',
  })
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/15-lda.conf' do
  source 'dovecot/15-lda.conf.erb'
  mode 00644
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/15-mailboxes.conf' do
  source 'dovecot/15-mailboxes.conf.erb'
  mode 00644
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/conf.d/20-managesieve.conf' do
  source 'dovecot/20-managesieve.conf.erb'
  mode 00644
  notifies :restart, 'service[dovecot]'
end

template '/etc/dovecot/dovecot-dict-auth.conf' do
  source 'dovecot/dovecot-dict-auth.conf.erb'
  mode 00644
  variables({
    :redis_prefix => node['mail.slimta.org']['redis_prefixes']['addresses'],
  })
  notifies :restart, 'service[dovecot]'
end

# vim:sw=2:ts=2:sts=2:et:ai:ft=ruby:
