require 'spec_helper'
describe 'krb5keytab_saveinhiera' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('krb5keytab_saveinhiera')).to eq('function_krb5keytab_saveinhiera')
  end

  it 'should throw an error when required parameters are absent' do
    lambda {
      scope.function_krb5keytab_saveinhiera([{:foo => :bar}])
    }.should(raise_error(Puppet::Error))
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_krb5keytab_saveinhiera(['bla'])
    }.should(raise_error(Puppet::Error))
  end

  it 'with valid types the function will go through but fail because couchrest does not exis' do
    lambda {
      scope.function_krb5keytab_saveinhiera([{'hiera_key' => 'test',
                                             'hiera_backend' => 'couchdb',
                                             'hiera_value' => 'test',
                                             'admin_server' => 'test',
                                             'ldap_ou' => 'test',
                                             'fqdn' => 'test'}])
    }.should(raise_error(RuntimeError))
  end

end
