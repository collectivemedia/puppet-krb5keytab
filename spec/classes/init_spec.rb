require 'spec_helper'
describe 'krb5keytab' do

  context 'with defaults for all parameters' do
    it { should contain_class('krb5keytab') }
  end
end
