require 'spec_helper_acceptance'

describe 'boss::role::puppet::server class' do
  context 'with default parameters' do
    let(:pp) do
      <<-MANIFEST
      include boss::role::puppet::server
      MANIFEST
    end

    it 'behaves idempotently' do
      idempotent_apply(pp)
    end

    describe file('/opt/puppetlabs/server') do
      it { is_expected.to be_directory }
    end

    describe service('puppetserver') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe service('puppetdb') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe service('puppetboard') do
      it { is_expected.to be_running }
      it { is_expected.to be_enabled }
    end

    describe command('/opt/puppetlabs/bin/r10k deploy environment -m --generate-types') do
      its(:exit_status) { is_expected.to eq 0 }
    end

    # FIXME: not working on rhel litmusimages (no ss command?)
    # describe port(8140) do
    #   it { is_expected.to be_listening }
    # end
  end
end
