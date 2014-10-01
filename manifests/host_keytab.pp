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
# This class manages the host's keytab (/etc/krb5.keytab)
# -----------------
# Requires stdlib

class krb5keytab::host_keytab inherits krb5keytab {

  #
  # Some parameters are needed by the script
  #

  if ($krb5keytab::admin_keytab == '*undefined*') {
    fail "Missing parameter 'krb5keytab::admin-keytab' (base64 encoded kerberos admin credential) is not defined in hiera"
  }

  if ($krb5keytab::admin_princ == '*undefined*') {
    fail "Missing parameter 'krb5keytab::admin-principal' (name of the kerberos admin principal) is not defined in hiera"
  }

  if ($krb5keytab::krb5_realm == '*undefined*') {
    fail "Missing parameter 'krb5keytab::krb5-realm' (Kerberos realm) is not defined in hiera"
  }

  if ($krb5keytab::hiera_backend == '*undefined*') {
    fail "Missing parameter 'krb5keytab::hiera-backend' (name of backend script to run) is not defined in hiera"
  }

  if ($krb5keytab::ldap_ou == '*undefined*') {
    fail "Missing parameter 'krb5keytab::ldap-ou' (where to put host keys in LDAP) is not defined in hiera"
  }

  if ($krb5keytab::krb5_admin_server == '*undefined*') {
    fail "Missing parameter 'krb5keytab::krb5-admin-server' (FQDN and optionally port of kerberos admin server) is not defined in hiera"
  }

  #
  # Determine the host keytab. The generator script will return the keytab
  # as base64 encoded. We will assume that hiera accepts the keytab as base64
  # encoded too.
  #
  
  if ($krb5keytab::h_keytab == '*undefined*') {

    # Store the keytab contents in a file on the server and pass in the
    # argument as a filename. Otherwise if there's an error the puppet agent might
    # be able to see the key in the error message, and that would be bad!

    $admin_keytab_file_path = krb5keytab_writefile(base64('decode',$krb5keytab::admin_keytab))

    #
    # Get the host keytab from the Kerberos server. This calls the
    # lib/puppet/parser/functions/krb5keytab_generatekt.rb file in this module.
    #

    $keytab = krb5keytab_generatekt( {
      admin_keytab => $admin_keytab_file_path,
      admin_principal => $krb5keytab::admin_princ,
      realm => $krb5keytab::krb5_realm,
      ldap_ou => $krb5keytab::ldap_ou,
      admin_server => $krb5keytab::krb5_admin_server,
      fqdn => $::fqdn
    } )

    #
    # Store the host keytab in your hiera database, so it doesn't have to get
    # regenerated the next time the puppet runs for this host. This calls the
    # lib/puppet/parser/functions/krb5keytab_saveinhiera.rb file in this module.
    #

    krb5keytab_saveinhiera( {
      hiera_key => 'krb5-keytab',
      hiera_value => base64('encode', $keytab),
      fqdn => $::fqdn,
      hiera_backend => $krb5keytab::hiera_backend,
      hiera_file_dir => hiera('krb5keytab::hiera-file-dir', ''),
      hiera_couchdb_hostname => hiera('krb5keytab::hiera-couchdb-hostname', '127.0.0.1'),
      hiera_couchdb_port => hiera('krb5keytab::hiera-couchdb-port', '5984'),
      hiera_couchdb_database => hiera('krb5keytab::hiera-couchdb-database', 'keytabs'),
      hiera_couchdb_username => hiera('krb5keytab::hiera-couchdb-username', ''),
      hiera_couchdb_password => hiera('krb5keytab::hiera-couchdb-password', ''),
    } )

  } else {

    ## Don't break with some legacy encoding from earlier versions
    $h_keytab_repl = regsubst($krb5keytab::h_keytab, '^BASE64:<(.+)>$', '\1', 'M')

    ## Decode the keytab
    $keytab = base64('decode', $h_keytab_repl)
  }

  #
  # Apply the host keytab
  #
  file { 'krb5-host-keytab':
      path    => '/etc/krb5.keytab',
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      replace => true,
      content => $keytab,
  }
}
