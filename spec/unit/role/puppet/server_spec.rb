# frozen_string_literal: true

require 'spec_helper'

describe 'boss::role::puppet::server', type: :class do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to contain_class('boss::profile::base') }
      it { is_expected.to contain_class('boss::profile::puppetserver') }
      it { is_expected.to contain_class('boss::profile::puppetdb') }
      it { is_expected.to contain_class('boss::profile::puppetboard') }
      it { is_expected.to contain_class('boss::profile::r10k') }
    end
  end
end
