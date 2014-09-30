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
# This function saves a value in hiera

module Puppet::Parser::Functions
  require 'tempfile'
  newfunction(:krb5keytab_saveinhiera) do |args_in|

    # Validate arguments
    args = args_in[0]
    fail "Usage: krb5keytab_saveinhiera(options_hash) -- #{args.inspect}" if ! args.is_a?(Hash)
    req_keys = %w{hiera_key fqdn hiera_backend hiera_value}
    req_keys.each do |key|
      fail "Required option key #{key} was not defined" if ! args.key?(key)
    end
    
    # Hand off to the appropriate handler
    backend = nil
    ## backend = HieraBackendHandler_File.new() if args['hiera_backend'] == 'file'
    backend = HieraBackendHandler_CouchDB.new() if args['hiera_backend'] == 'couchdb'
    fail "Unrecognized or unhandled hiera backend handler: #{args['hiera_backend']}" if backend.nil?
    
    return backend.save(args)
    
  end
  
  ########
  # HieraBackendHandler_CouchDB -- write/update value into CouchDB
  ########
  
  class HieraBackendHandler_CouchDB
    
    def initialize
      begin
        require 'rubygems'
        require 'couchrest'
      rescue LoadError => err
        fail "Failed to load a needed gem -- did you install the 'couchrest' gem? (#{err.message})"
      end
    end
    
    def save (args)
      
      # URL to Couch DB
      @url = "http://"
      if ! args['hiera_couchdb_username'].empty? or ! args['hiera_couchdb_password'].empty?
        @url = "http://#{args['hiera_couchdb_username']}:#{args['hiera_couchdb_password']}@"
      end
      @url.concat(args['hiera_couchdb_hostname'])
      @url.concat(":" + args['hiera_couchdb_port']) if ! args['hiera_couchdb_port'].empty?
      
      # Connect to CouchDB
      fqdn = args['fqdn']
      begin
        couch = CouchRest.new(@url)
        db = couch.database(args['hiera_couchdb_database'])
        doc = db.get(fqdn)
      rescue Errno::ECONNREFUSED => err
        fail "Connection refused to couchdb! (#{err.message})"
      rescue RestClient::Unauthorized => err
        fail "Authentication failure on couchdb (username/password are wrong or required)! (#{err.message})"
      rescue RestClient::ResourceNotFound => err
        new_doc = { '_id' => fqdn, args['hiera_key'] => args['hiera_value'] }
        begin
          db.save_doc(new_doc)
          return
        rescue => err
          fail "Unable to save value into couchdb: #{err.message}"
        end
      rescue => err
        fail "Unknown error connecting to couchdb: #{err.message}"
      end
      
      # Save the value in couchdb      
      begin
        doc[args['hiera_key']] = args['hiera_value']
        db.save_doc(doc)
      rescue => err
        fail "Unable to save value into couchdb: #{err.message}"
      end
      
      # Done
      return
      
    end
  end
end

