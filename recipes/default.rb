#
# Cookbook Name:: mail.slimta.org
# Recipe:: default
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

include_recipe 'slimta'

package 'redis-server' do
  action :install
end

include_recipe 'mail.slimta.org::edge'
include_recipe 'mail.slimta.org::relay'

directory '/etc/slimta/certs' do
  mode 0755
  action :create
end

['cert', 'key'].each do |ssl_file|
  file ::File.join('/etc/slimta/certs', "#{ ssl_file }.pem") do
    content node['mail.slimta.org']['ssl'][ssl_file]
    mode 0644
    action :create
    notifies :restart, 'service[slimta-edge]'
    notifies :restart, 'service[slimta-relay]'
  end
end

service 'slimta-edge' do
  action [:start, :enable]
  subscribes :restart, 'slimta_app[edge]'
end

service 'slimta-relay' do
  action [:start, :enable]
  subscribes :restart, 'slimta_app[relay]'
end

# vim:sw=2:ts=2:sts=2:et:ai:ft=ruby:
