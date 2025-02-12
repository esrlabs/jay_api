# frozen_string_literal: true

require 'jay_api/git/gerrit/gitiles_helper'

RSpec.describe JayAPI::Git::Gerrit::GitilesHelper do
  subject(:test_object) { test_class.new }

  let(:test_class) do
    Class.new do
      include JayAPI::Git::Gerrit::GitilesHelper
    end
  end

  describe '#translate_gerrit_url' do
    subject(:method_call) { test_object.translate_gerrit_url(url) }

    context 'with a URL on the main gerrit instance' do
      let(:url) { 'ssh://jenkins@gerrit.local:29418/XYZ01/code' }
      let(:expected_url) { 'https://gerrit.local/plugins/gitiles/XYZ01/code' }

      it 'correctly translates the URL' do
        expect(method_call).to eq(expected_url)
      end
    end

    context "with a URL in XYZ01's gerrit" do
      let(:url) { 'ssh://xyz01-sources.local:29418/XYZ01/Requirements' }
      let(:expected_url) { 'https://xyz01-sources.local/plugins/gitiles/XYZ01/Requirements' }

      it 'correctly translates the URL' do
        expect(method_call).to eq(expected_url)
      end
    end
  end

  describe '#gitiles_url' do
    subject(:method_call) do
      test_object.gitiles_url(
        repository: repository, refspec: refspec, path: path, line_number: line_number
      )
    end

    context 'when the refspec is a branch and the URL contains a user name' do
      let(:repository) { 'ssh://jenkins@gerrit.local:29418/XYZ01/code' }
      let(:refspec) { 'master' }
      let(:path) { 'bsw/bsw/svcDemAdapter/test/src/SvcDemTest.cpp' }
      let(:line_number) { 502 }

      let(:expected_url) { 'https://gerrit.local/plugins/gitiles/XYZ01/code/+/master/bsw/bsw/svcDemAdapter/test/src/SvcDemTest.cpp#502' }

      it 'generates the expected Gitiles URL' do
        expect(method_call).to eq(expected_url)
      end
    end

    context 'when the repository URL contains credentials and the file name starts with .' do
      let(:repository) { 'ssh://jenkins:Th3P4$$w0rd@gerrit.local:29418/tools/elite' }
      let(:refspec) { '5f70691042a2046d571848ceb058dfb84495df5e' }
      let(:path) { './spec/projects/xyz01/FuSi-BSP/Safe_E2E/check_irq_lock_spec.rb' }
      let(:line_number) { 63 }

      let(:expected_url) { 'https://gerrit.local/plugins/gitiles/tools/elite/+/5f70691042a2046d571848ceb058dfb84495df5e/./spec/projects/xyz01/FuSi-BSP/Safe_E2E/check_irq_lock_spec.rb#63' }

      it 'generates the expected Gitiles URL' do
        expect(method_call).to eq(expected_url)
      end
    end

    context "when the repository is hosted on XYZ01's Gerrit instance and the line number is a string" do
      let(:repository) { 'ssh://xyz01-sources.local:29418/XYZ01/Requirements' }
      let(:refspec) { '52c82ed1017b0a09a3e0cc918557d7040d790832' }
      let(:path) { '/modules/COM_Core/COM_Core.dim' }
      let(:line_number) { '171' }

      let(:expected_url) { 'https://xyz01-sources.local/plugins/gitiles/XYZ01/Requirements/+/52c82ed1017b0a09a3e0cc918557d7040d790832/modules/COM_Core/COM_Core.dim#171' }

      it 'generates the expected Gitiles URL' do
        expect(method_call).to eq(expected_url)
      end
    end

    context 'when the repository was cloned via HTTPS and no line number was provided' do
      let(:repository) { 'https://xyz01.automation@gerrit.local/a/XYZ01/code' }
      let(:refspec) { 'a80ca3f9a7b06948c3ea02892b19d7f30e62e70a' }
      let(:path) { 'bsw/requirements/safety/req_SC_Architecture.yml' }
      let(:line_number) { nil }

      let(:expected_url) { 'https://gerrit.local/plugins/gitiles/XYZ01/code/+/a80ca3f9a7b06948c3ea02892b19d7f30e62e70a/bsw/requirements/safety/req_SC_Architecture.yml' }

      it 'generates the expected Gitiles URL' do
        expect(method_call).to eq(expected_url)
      end
    end

    describe 'url caching' do
      let(:first_method_call) do
        test_object.gitiles_url(
          repository: 'ssh://jenkins@gerrit.local:29418/XYZ01/code',
          refspec: 'master',
          path: 'bsw/bsw/svcDemAdapter/test/src/SvcDemTest.cpp',
          line_number: 502
        )
      end

      let(:second_method_call) do
        test_object.gitiles_url(
          repository: 'ssh://jenkins@gerrit.local:29418/XYZ01/code',
          refspec: '1c52fa401f7811b8a92965796fde9906231e97fe',
          path: 'bsw/requirements/safety/req_safeCenterLockActuator.yml',
          line_number: nil
        )
      end

      before do
        allow(URI).to receive(:parse).and_call_original
      end

      it 'parses the repository URL only once' do
        expect(URI).to receive(:parse).once
        first_method_call
        second_method_call
      end
    end
  end
end
