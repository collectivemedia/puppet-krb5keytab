require 'spec_helper'
describe 'krb5keytab' do

  context 'with given parameters' do
    let(:params) {{:admin_keytab => 'test',:admin_princ => 'test',
                   :krb5_realm => 'test', :hiera_backend => 'test',
                   :krb5_admin_server => 'test', :ldap_ou => 'test',
                   :h_keytab => 'test' }}
    it { should contain_class('krb5keytab') }
    it { should contain_file('krb5-host-keytab')}
    it { should contain_class('krb5keytab::host_keytab')}
  end
end
