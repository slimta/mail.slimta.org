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

tls = {
  'main' => {
    'keyfile' => '/etc/slimta/certs/key.pem',
    'certfile' => '/etc/slimta/certs/cert.pem',
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

  'inbound_http' => {
    'type' => 'http',
    'queue' => 'inbound',
    'rules' => 'inbound',
    'interface' => '',
    'port' => 8025,
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
}

rules = {
  'inbound' => {
    'banner' => '{fqdn} ESMTP slimta.org Mail Delivery Agent',
    'dnsbl' => 'zen.spamhaus.org',
    'reject_spf' => ['fail'],
    'reject_spam' => 'spamassassin',
    'only_recipients' => node['mail.slimta.org']['allowed_addresses'],
  },

  'outbound' => {
    'banner' => '{fqdn} ESMTP slimta.org Mail Submission Agent',
    'dnsbl' => 'zen.spamhaus.org',
    'require_credentials' => node['mail.slimta.org']['send_credentials'],
  },
}

queue = {
  'inbound' => {
    'type' => 'redis',
    'prefix' => 'slimta:inbound:',
    'policies' => [
      {'type' => 'add_date_header'},
      {'type' => 'add_messageid_header'},
      {'type' => 'add_received_header'},
      {
        'type' => 'forward',
        'everything' => node['mail.slimta.org']['forward_address']
      },
    ],
  },

  'outbound' => {
    'type' => 'redis',
    'prefix' => 'slimta:outbound:',
    'policies' => [
      {'type' => 'add_date_header'},
      {'type' => 'add_messageid_header'},
      {'type' => 'add_received_header'},
      {'type' => 'split_recipient_domain'},
    ],
  },
}

slimta_app 'edge' do
  cookbook 'slimta'
  service_name 'slimta-edge'
  conf_files :logging => 'logging.conf', :rules => 'rules.conf'
  log_file 'slimta.log'

  tls tls
  edge edge
  rules rules
  queue queue

  notifies :restart, 'service[slimta-edge]'
end

service 'slimta-edge' do
  action [:start, :enable]
end

# vim:sw=2:ts=2:sts=2:et:ai:ft=ruby:
