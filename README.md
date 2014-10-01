# krb5keytab

[![Build Status](https://travis-ci.org/collectivemedia/puppet-krb5keytab.svg?branch=master)](https://travis-ci.org/collectivemedia/puppet-krb5keytab)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with krb5keytab](#setup)
    * [What krb5keytab affects](#what-krb5keytab-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with krb5keytab](#beginning-with-krb5keytab)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module generates Kerberos keytabs for hosts (manages the /etc/krb5.keytab file) without
the need to place a Kerberos administrator credential on the host.

This module was developed for, and tested with, MIT Kerberos and OpenLDAP on CentOS 6.

## Module Description

This module uses custom functions to create the principal and download the keytab
on the puppet master, and hiera to store the generated keytabs. The design of this
process eliminates the need to call exec{} with a Kerberos administrative credential
on every host.

In addition, the module stores the generated keytab file in hiera, so that it is
cached for the next run. Some Kerberos implementations (notably MIT) randomize the
password each time the keytab is downloaded, so without this feature a new keytab
would be generated for each Puppet run. The module is currently able to store the
generated key into CouchDB. Support for file/directory hiera is planned. 

## Setup

### What krb5keytab affects

The only file on the target system that is affected is /etc/krb5.keytab, which
contains the host's Kerberos principal. This keytab is used to authenticate the
host itself to network services - for example, sssd uses this keytab to
authenticate the host to the LDAP server.

### Setup Requirements

There are numerous assumptions and configuration parameters required to make full
use of this module.

#### Assumptions

1. You need to have OpenLDAP and Kerberos running and working in your environment.

2. You need to have at least one Kerberos administrative principal created, which has (at minimum)
the ability to add principals, change passwords, inquire, and list ("clia" in kadm5.acl). We suggest
creating a separate principal for your Puppet master, e.g.: `puppetmaster@YOUR-REALM.COM`

You would place a corresponding entry in the `/var/kerberos/krb5kdc/kadm5.acl` file:

`puppetmaster@YOUR-REALM.COM   clia`

3. You need to have Hiera running. If you want to use the feature of this module that
saves newly generated keytabs in hiera for you, then your Hiera must be backed by
CouchDB (see https://github.com/crayfishx/hiera-http). We will be adding support for
a file/directory based Hiera setup in the future.

### Beginning with krb5keytab

krb5keytab is configured with numerous parameters in Hiera and/or parameters passed to
the class. Please see the "Usage" section for details.

## Usage

krb5keytab is configured with numerous parameters in Hiera and/or parameters passed to
the class. Parameters passed to the class take precedence over Hiera.

#### Admin Keytab (required)

Hiera: `krb5keytab::admin-keytab`

Parameter to class: `admin_keytab`

The **base64 encoded** keytab for the administrative Kerberos principal.

* How to create a keytab file: https://kb.iu.edu/d/aumh#create
* How to base64 encode the keytab: `base64 username.keytab`

Example (this is just random data encoded as BASE64):

    VQPlowXZxtrKW8sZv3Ehg2T7W+y1jjxzILnOOHM/GHzykphIHXbvMmezZpupLB3wns8/YNPi4CVM
    YGe1rWmCZ7hU0SmEdJNQ9/x2nd2j7YudunhVHAsA8lvE32L0TY8VbpQX4d1y0YxaJeMDksE+M17N
    JVKiWeQD7o92guSzp1wapzCA08yZJXZV36Uw21U87NgZPhdbhDE/kzeFep5hrxEIXylaQW8zRCGc
    LT/l8RjPCFkjXzxn3VKWsaVaaFC2FCDaEMqkFcxcX5UxatnBqcNtlbR0WTNUiAYu9UDdEz1KVGZc
    L5Vxbj3dSmsMm8M2peSSoOl3FgSTUFyqJ9xoiOIPbrJz6MkId1oTW31Lal0hmqTAxZLmYCLNEb6y
    yB9J5APTNEW1SPKma7rXmmOQtWZuthYsasWRbFdZKsC96h6jVHzX/pngAhxPBPjEyYUkNBeFSO9W
    KIpn3f0KXiFt0+i/Y6N5ZmsODf6fzKUFMW24HogjzleqqhUYEiNdpmZKj5f3iP0Lg2PZpmNFeTzO
    2tw6VebNZTCc9REw98sh8L4D0OAF5ProTItJNditAg==

#### Admin Principal (required)

Hiera: `krb5keytab::admin-principal`

Parameter to class: `admin_principal`

The principal's name of your administrative Kerberos principal.

Example:

`puppetmaster@YOUR-REALM.COM`

#### Kerberos Realm (required)

Hiera: `krb5keytab::krb5-realm`

Parameter to class: `krb5_realm`

The Kerberos realm. In other words, the (usually capitalized) portion of principal
names that come after the "@" sign. This is often part of your domain name.

Example:

`YOUR-REALM.COM`

#### Hiera Backend (optional)

Hiera: `krb5keytab::hiera-backend`

Parameter to class: `hiera_backend`

The type of Hiera backend you run, so that the module can **write** keytabs that are
generated into that Hiera backend for you. The options available are:

* `none` (or undefined) -- Do not store generated keytabs in Hiera
* `file` -- Store generated keytabs into a directory structure
* `couchdb` -- Store generated keytabs into a CouchDB

Note that if you select `none` or undefined, the code to generate a keytab will be
executed each time a Puppet catalog is compiled for a node. On MIT Kerberos, this
will result in randomization of the keytab for the host every time. This is probably
undesirable.

#### LDAP Organizational Unit (required)

Hiera: `krb5keytab::ldap-ou`

Parameter to class: `ldap_ou`

The place in your LDAP tree where Kerberos principals for hosts should be created.

Example:

`ou=hosts,dc=your-realm,dc=com`

#### Kerberos Admin Server FQDN or IP Address (required)

Hiera: `krb5keytab::krb5-admin-server`

Parameter to class: `krb5_admin_server`

The fully qualified domain name of your Kerberos admin server. This is that server that
will be contacted to identify, list, create, and obtain the host principals.

Example:

`kerberos1.your-realm.com`

### Files Hiera Configuration Parameters

The following settings are supported if you set `krb5keytab::hiera-backend` = `files`

#### Hiera File Directory (required if hiera-backend = files)

Hiera: `krb5keytab::hiera-file-dir`

Parameter to class: `hiera_file_dir`

The directory where files are created with the host keytabs (this must exist on the Puppet master).
Within this directory, files named `${::fqdn}.yaml` will be created. Each file will have a field named
"krb5-keytab" with the BASE64 encoded keytab.

Use a separate subdirectory for this from all of your other Hiera data. This module will refuse to
overwrite files that contain data not created by this module. 

### CouchDB Hiera Configuration Parameters

The following settings are supported if you set `krb5keytab::hiera-backend` = `couchdb`.

The 'couchrest' gem is required for krb5keytab to write to a CouchDB.

#### CouchDB Server Hostname (optional)

Hiera: `krb5keytab::hiera-couchdb-hostname`

Parameter to class: `hiera_couchdb_hostname`

The fully qualified domain name or IP address of your CouchDB server. Defaults to 127.0.0.1.

#### CouchDB Server Port Number (optional)

Hiera: `krb5keytab::hiera-couchdb-port`

Parameter to class: `hiera_couchdb_port`

The port number that CouchDB is running on. Defaults to 5984.

#### CouchDB Server Database Name (optional)

Hiera: `krb5keytab::hiera-couchdb-database`

Parameter to class: `hiera_couchdb_database`

The database name in which to store generated keytabs. Defaults to "keytabs".

Note: Within that database, a document named after ${::fqdn} will be generated, and therein a field named "krb5-keytab" will be created and populated with the BASE64 encoded kerberos keytab.

#### CouchDB Basic Auth Credentials (optional)

Hiera: `krb5keytab::hiera-couchdb-username` and `krb5keytab::hiera-couchdb-password`

Parameter to class: `hiera_couchdb_username` and `hiera_couchdb_password`

If CouchDB has basic authentication turned on, supply the username and password to connect. This account must have the ability to create and update records in the assigned database.

## Reference

### Classes

#### krb5keytab::host_keytab

Main class to generate and install a host keytab.

This class does not take parameters. The connection and credential parameters for Kerberos are stored in Hiera. The keytab is generated for `${::fqdn}`.

### Custom Functions

#### krb5keytab_generatekt(options_hash)

options_hash is a hash containing the following keys:

* admin_principal - Name of the administrative principal. See krb5keytab::admin-principal hiera parameter.
* admin_keytab - The **full path** to a file containing the administrative keytab.
* ldap_ou - See krb5keytab::ldap-ou hiera parameter.
* admin_server - See krb5keytab::krb5-admin-server hiera parameter.
* realm - See krb5keytab::krb5-realm hiera parameter.
* fqdn - FQDN of the host whose principal is needed.

From this a host principal is built: `"host/#{args['fqdn']}@#{args['realm']}"`

The "kadmin" command is used to create the principal if needed, and then to retrieve the keytab.

This method returns the content of the keytab (which is binary data).

#### krb5keytab_saveinhiera(options_hash)

options_hash is a hash containing the following keys:

* hiera_key - Name of the key to create in Hiera (in our context, "krb5-keytab")
* fqdn - FQDN of the host whose principal is needed.
* hiera_backend - One of 'none', 'files', or 'couchdb'
* hiera_value - Value to write in Hiera (in our context, the BASE64 encoded keytab)

No return value.

#### krb5keytab_writefile(content)

Creates a temporary file with the content supplied as the argument.

Returns the path to the temporary file.

## Limitations

This module was developed on CentOS 6 for OpenLDAP and Kerberos. While we believe that
the underlying code will probably work with other flavors of Linux and other
implementations of LDAP and Kerberos, this has not been tested.

## Development

If you wish to contribute, please submit a pull request. All contributions must be
licensed to us under the Apache 2.0 license.

## Contributors

This module was originally developed at Collective, Inc. (http://www.collective.com).
We gratefully acknowledge the following contributors:

* Kevin Paulisse (original design and code)
* Sarguru Nathan (builds and tests)
* Millie Kim (file backend for Hiera storage)
