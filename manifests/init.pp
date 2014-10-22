#   Copyright 2014 Collective, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# -------------------------------------------------------
#
class krb5keytab (
$admin_keytab = hiera('krb5keytab::admin-keytab', '*undefined*'),
$admin_princ = hiera('krb5keytab::admin-principal', '*undefined*'),
$krb5_realm = hiera('krb5keytab::krb5-realm', '*undefined*'),
$hiera_backend = hiera('krb5keytab::hiera-backend', '*undefined*'),
$ldap_ou = hiera('krb5keytab::ldap-ou', '*undefined*'),
$krb5_admin_server = hiera('krb5keytab::krb5-admin-server', '*undefined*'),
$h_keytab = hiera('krb5-keytab', '*undefined*')
){

  class { 'krb5keytab::host_keytab': } ->
  Class['krb5keytab']
}
