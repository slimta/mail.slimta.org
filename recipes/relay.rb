#
# Cookbook Name:: mail.slimta.org
# Recipe:: relay
#
# Copyright 2014, Ian Good
#
# All rights reserved - Do Not Redistribute
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

queue = {
  'inbound' => {
    'type' => 'redis',
    'prefix' => node['mail.slimta.org']['redis_prefixes']['inbound'],
    'relay' => 'inbound',
    'bounce_queue' => 'outbound',
  },

  'outbound' => {
    'type' => 'redis',
    'prefix' => node['mail.slimta.org']['redis_prefixes']['outbound'],
    'relay' => 'outbound',
    'retry' => {
      'maximum' => 3,
      'delay' => '60*x',
    },
  },
}

relay = {
  'inbound' => {
    'type' => 'lmtp',
    'ehlo_as' => 'mail.slimta.org',
  },

  'outbound' => {
    'type' => 'mx',
    'ehlo_as' => 'mail.slimta.org',
    'ipv4_only' => true,
  },
}

slimta_app 'relay' do
  cookbook 'slimta'
  service_name 'slimta-relay'
  conf_files :logging => 'logging.conf', :rules => 'rules.conf'
  log_file 'slimta.log'
  user 'slimta'
  group 'mail'

  tls tls
  queue queue
  relay relay

  notifies :restart, 'service[slimta-relay]'
end

service 'slimta-relay' do
  action [:start, :enable]
end

# vim:sw=2:ts=2:sts=2:et:ai:ft=ruby:
