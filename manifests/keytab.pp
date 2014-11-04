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
# This class manages the a kerberos principal and possibly a kerberos keytab
# -----------------
# Requires stdlib

define krb5keytab::keytab (
	$admin_keytab = hiera('krb5keytab::admin-keytab', '*undefined*'),
	$admin_princ = hiera('krb5keytab::admin-principal', '*undefined*'),
	$krb5_realm = hiera('krb5keytab::krb5-realm', '*undefined*'),
	$hiera_backend = hiera('krb5keytab::hiera-backend', '*undefined*'),
	$ldap_ou = hiera('krb5keytab::ldap-ou', '*undefined*'),
	$krb5_admin_server = hiera('krb5keytab::krb5-admin-server', '*undefined*'),
	$hiera_key = '*undefined*',
	$h_keytab = '*undefined*',
	$keytab = '*null*',
	$keytab_owner = 'root',
  $keytab_group = 'root',
  $keytab_mode = '0600',
) {
  
  #
  # Verify required parameters
  #
  
  if ($admin_keytab == '*undefined*') {
    fail "Missing parameter 'krb5keytab::admin-keytab' (base64 encoded kerberos admin credential) is not defined in hiera"
  }

  if ($admin_princ == '*undefined*') {
    fail "Missing parameter 'krb5keytab::admin-principal' (name of the kerberos admin principal) is not defined in hiera"
  }

  if ($krb5_realm == '*undefined*') {
    fail "Missing parameter 'krb5keytab::krb5-realm' (Kerberos realm) is not defined in hiera"
  }

  if ($hiera_backend == '*undefined*') {
    fail "Missing parameter 'krb5keytab::hiera-backend' (name of backend script to run) is not defined in hiera"
  }

  if ($ldap_ou == '*undefined*') {
    fail "Missing parameter 'krb5keytab::ldap-ou' (where to put host keys in LDAP) is not defined in hiera"
  }

  if ($krb5_admin_server == '*undefined*') {
    fail "Missing parameter 'krb5keytab::krb5-admin-server' (FQDN and optionally port of kerberos admin server) is not defined in hiera"
  }
  
  #
  # Determine the proper hiera name for the keytab
  #
  
  if ($hiera_key == '*undefined*') {
    if ($name =~ /^host\//) {
      $hiera_key_used = 'krb5-keytab'
    } else {
      $hiera_key_used = regsubst($name, '[^\w\-\/\.\@]', '_', 'G')
    }
  } else {
    $hiera_key_used = $hiera_key
  }
  
  #
  # Build/obtain the keytab
  #
  
  if ($h_keytab == '*undefined*') {
    $keytab_in_hiera = hiera($hiera_key_used, '*undefined*')
    if ($keytab_in_hiera == '*undefined*') {
      
	    # Store the keytab contents in a file on the server and pass in the
	    # argument as a filename. Otherwise if there's an error the puppet agent might
	    # be able to see the key in the error message, and that would be bad!
      
      $admin_keytab_file_path = krb5keytab_writefile(base64('decode',$admin_keytab))
      
	    #
	    # Get the keytab from the Kerberos server. This calls the
	    # lib/puppet/parser/functions/krb5keytab_generatekt.rb file in this module.
	    #
	
	    $keytab_from_generatekt = krb5keytab_generatekt( {
	      admin_keytab => $admin_keytab_file_path,
	      admin_principal => $admin_princ,
	      realm => $krb5_realm,
	      ldap_ou => $ldap_ou,
	      admin_server => $krb5_admin_server,
	      principal => $name,
	    } )
	
	    #
	    # Store the host keytab in your hiera database, so it doesn't have to get
	    # regenerated the next time the puppet runs for this host. This calls the
	    # lib/puppet/parser/functions/krb5keytab_saveinhiera.rb file in this module.
	    #
	
	    krb5keytab_saveinhiera( {
	      hiera_key => $hiera_key_used,
	      hiera_value => base64('encode', $keytab_from_generatekt),
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
	    $keytab_content_repl = regsubst($keytab_in_hiera, '^BASE64:<(.+)>$', '\1', 'M')
	    $keytab_content = base64('decode', $keytab_content_repl)
    }
  } else {
    ## Don't break with some legacy encoding from earlier versions
    $keytab_content_repl = regsubst($h_keytab, '^BASE64:<(.+)>$', '\1', 'M')
    $keytab_content = base64('decode', $keytab_content_repl)
  }
  
  #
  # Apply the keytab
  #
  
  if ($keytab != '*null*') {
	  file { $keytab:
	      path    => $keytab,
	      owner   => $keytab_owner,
	      group   => $keytab_group,
	      mode    => $keytab_mode,
	      replace => true,
	      content => $keytab_content,
	  }
  }
}