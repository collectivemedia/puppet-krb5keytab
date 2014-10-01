require 'spec_helper'
describe 'krb5keytab_generatekt' do

  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it 'should exist' do
    expect(Puppet::Parser::Functions.function('krb5keytab_generatekt')).to eq('function_krb5keytab_generatekt')
  end

  it 'should throw an error when required parameters are absent' do
    lambda {
      scope.function_krb5keytab_generatekt([{:foo => :bar}])
    }.should(raise_error(Puppet::Error))
  end

  it 'should throw an error on invalid types' do
    lambda {
      scope.function_krb5keytab_generatekt(['bla'])
    }.should(raise_error(Puppet::Error))
  end

  it 'with valid types the function will go through but fail because the test keytab doesnt exist' do
    lambda {
      scope.function_krb5keytab_generatekt([{'admin_keytab' => 'test',
                                             'admin_principal' => 'test',
                                             'realm' => 'test',
                                             'admin_server' => 'test',
                                             'ldap_ou' => 'test',
                                             'fqdn' => 'test'}])
    }.should(raise_error(Errno::ENOENT))
  end

end
