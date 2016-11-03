#
# Cookbook Name:: mail.slimta.org
# Recipe:: edge
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

package 'spamassassin' do
  action :install
end

service 'spamassassin' do
  action [:start, :enable]
end

tls = {
  'main' => {
    'keyfile' => node['mail.slimta.org']['certs']['key'],
    'certfile' => node['mail.slimta.org']['certs']['cert'],
  },
}

edge = {
  'inbound' => {
    'type' => 'smtp',
    'queue' => 'inbound',
    'rules' => 'inbound',
    'interface' => '',
    'port' => 25,
  },

  'inbound_ssl' => {
    'type' => 'smtp',
    'queue' => 'inbound',
    'rules' => 'inbound',
    'interface' => '',
    'port' => 465,
    'tls_immediately' => true,
  },

  'outbound' => {
    'type' => 'smtp',
    'queue' => 'outbound',
    'rules' => 'outbound',
    'interface' => '',
    'port' => 587,
  },

  'outbound_restricted' => {
    'type' => 'smtp',
    'queue' => 'outbound',
    'rules' => 'outbound_restricted',
    'interface' => '127.0.0.1',
    'port' => 1587,
  },
}

redis_lookup_prefix = node['mail.slimta.org']['redis_prefixes']['addresses']
lookup = {
  'addresses' => {
    'type' => 'redis',
    'key_template' => "#{ redis_lookup_prefix }{address}",
  },

  'outbound_sender' => {
    'type' => 'redis',
    'key_template' => "#{ redis_lookup_prefix }__outbound_sender__",
  },
}

rules = {
  'inbound' => {
    'banner' => '{fqdn} ESMTP slimta.org Mail Delivery Agent',
    'dnsbl' => 'zen.spamhaus.org',
    'reject_spf' => ['fail'],
    'reject_spam' => 'spamassassin',
    'lookup_recipients' => 'addresses',
  },

  'outbound' => {
    'banner' => '{fqdn} ESMTP slimta.org Mail Submission Agent',
    'dnsbl' => 'zen.spamhaus.org',
    'lookup_credentials' => 'addresses',
  },

  'outbound_restricted' => {
    'banner' => '{fqdn} ESMTP slimta.org Mail Submission Agent',
  },
}

queue = {
  'inbound' => {
    'type' => 'redis',
    'prefix' => node['mail.slimta.org']['redis_prefixes']['inbound'],
    'policies' => [
      {'type' => 'add_date_header'},
      {'type' => 'add_messageid_header'},
      {'type' => 'add_received_header'},
      {'type' => 'lookup', 'lookup_group' => 'addresses'},
    ],
  },

  'outbound' => {
    'type' => 'redis',
    'prefix' => node['mail.slimta.org']['redis_prefixes']['outbound'],
    'policies' => [
      {'type' => 'add_date_header'},
      {'type' => 'add_messageid_header'},
      {'type' => 'add_received_header'},
      {'type' => 'split_recipient_domain'},
      {
        'type' => 'lookup',
        'lookup_group' => 'outbound_sender',
        'on_sender' => true,
        'on_recipients' => false,
      },
    ],
  },
}

slimta_app 'edge' do
  cookbook 'slimta'
  service_name 'slimta-edge'
  conf_files :logging => 'logging.conf', :rules => 'rules.conf'
  log_file 'slimta.log'
  user 'slimta'
  group 'mail'

  tls tls
  lookup lookup
  edge edge
  rules rules
  queue queue

  notifies :restart, 'service[slimta-edge]'
end

service 'slimta-edge' do
  action [:start, :enable]
end

# vim:sw=2:ts=2:sts=2:et:ai:ft=ruby:
