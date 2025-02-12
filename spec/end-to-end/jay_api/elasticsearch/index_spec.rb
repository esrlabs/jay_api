# frozen_string_literal: true

require 'jay_api/elasticsearch/query_builder'

require_relative '../index'
require_relative '../../../support/matchers/have_duration/matcher'

RSpec.describe JayAPI::Elasticsearch::Index do
  include_context 'with JayAPI::Elasticsearch::Index'

  describe '#search' do
    subject(:search) { index.search(query) }

    let(:retrieved_data) { search.all.to_a }

    let(:max_result_window) do
      client.transport_client
            .indices
            .get_settings(index: index_name)[index_name]['settings']['index']['max_result_window'] || 10_000
    end

    let(:query) do
      {
        'query' => {
          'match_all' => {}
        }
      }
    end

    let(:nr_docs) { doc_id_list.size }
    let(:retrieved_ids) { retrieved_data.map { |doc| doc['_source']['doc_id'] } }

    before do
      next if RSpec.current_example.metadata[:skip_before]

      unless client.transport_client.indices.exists(index: index_name)
        doc_id_list.each { |doc_id| index.push({ 'doc_id' => doc_id }) }
        sleep 4 # For Elasticsearch to process the data
      end
    end

    context "when the query size is under the 'max_result_window' limit" do
      let(:index_name) { 'index_spec_search_below_max_result_window' }
      let(:nr_of_unique_docs) { 8000 }
      let(:doc_id_list) { (1..nr_of_unique_docs).to_a }

      # rubocop:disable RSpec/ExpectInHook
      before do
        # validates the precondition for the test
        expect(nr_docs).to be < max_result_window
      end
      # rubocop:enable RSpec/ExpectInHook

      it 'contains all of the uploaded docs' do
        expect(retrieved_ids).to eq(doc_id_list)
      end
    end

    context "when the query size is above the 'max_result_window' limit" do
      let(:index_name) { 'index_spec_search_above_max_result_window' }
      let(:nr_of_unique_docs) { 10_100 }
      let(:doc_id_list) { (1..nr_of_unique_docs).to_a } # > max_result_window

      # rubocop:disable RSpec/ExpectInHook
      before do
        # validates the precondition for the test
        expect(nr_docs).to be > max_result_window
      end
      # rubocop:enable RSpec/ExpectInHook

      context "without specifying the 'type' parameter" do
        it 'does not contain all of the uploaded Docs' do
          expect(retrieved_ids).not_to eq(doc_id_list)
        end

        it 'only returns the allowed maximum of documents' do
          expect(retrieved_data.size).to (be < nr_docs).and(be max_result_window)
        end
      end

      context "when 'type' parameter is set to 'search_after'" do
        subject(:search) { index.search(query, type: :search_after) }

        context "with a 'sort' in the query body" do
          let(:query) do
            {
              'size' => 10,
              'query' => {
                'match_all' => {}
              },
              'sort' => {
                'doc_id' => 'asc'
              }
            }
          end

          it 'contains all of the uploaded docs' do
            expect(retrieved_ids).to eq(doc_id_list)
          end
        end

        context "without a 'sort' in the query body" do
          it 'raises an error' do
            expect { search.all { nil } }.to raise_error(
              JayAPI::Elasticsearch::Errors::SearchAfterError,
              "'sort' attribute must be specified in the query when using 'search_after' parameter"
            )
          end
        end
      end
    end

    shared_examples_for 'Client re-raising an error' do
      it 're-raises a server error after the expected time and logs all connection attempts', skip_before: true do
        expect do
          expect { retrieved_data }.to raise_error(
            Elasticsearch::Transport::Transport::Errors::NotFound,
            error_msg
          )
        end.to have_duration(within(1.second).of(expected_total_time))

        expect(array_appender.logs).to eq(expected_log)
      end
    end

    describe 'server error' do
      context 'when a non-re-triable error is raised' do
        let(:index_name) { 'some_non_existent_index' }

        let(:formatted_error_msg) do
          <<~JSON
            {
              "error": {
                "root_cause": [{
                  "type": "index_not_found_exception",
                  "reason": "no such index [some_non_existent_index]",
                  "resource.type": "index_or_alias",
                  "resource.id": "some_non_existent_index",
                  "index_uuid": "_na_",
                  "index": "some_non_existent_index"
                }],
                "type": "index_not_found_exception",
                "reason": "no such index [some_non_existent_index]",
                "resource.type": "index_or_alias",
                "resource.id": "some_non_existent_index",
                "index_uuid": "_na_",
                "index": "some_non_existent_index"
              },
              "status": 404
            }
          JSON
        end

        let(:expected_log) { [] }

        let(:error_msg) do
          "[404] #{JSON.generate(JSON.parse(formatted_error_msg))}"
        end

        it 're-raises the error without performing any retries', skip_before: true do
          expect do
            expect { retrieved_data }.to raise_error(
              Elasticsearch::Transport::Transport::Errors::NotFound, error_msg
            )
          end.to have_duration(0..0.1) # Should be pretty much instantaneous.

          expect(array_appender.logs).to eq(expected_log)
        end
      end

      context 'when a re-triable error is raised',
              skip: 'No way to reliable test this with the dockerized Elasticsearch' do
        # These tests are currently disabled because there isn't a reliable way
        # of triggering a re-triable error with the dockerized Elasticsearch
        # instance. An alternative needs to be found to test this.

        context 'without specifying any parameters upon client creation' do
          let(:client) do
            client_factory.create # default values: (max_attempts: 4, wait_strategy: :geometric, wait_interval: 2)
          end

          let(:expected_log) do
            [
              "#{error_msg} occurred",
              'Sleeping: 2.00 s',
              'Retrying... (There are 3 retries left)',
              "#{error_msg} occurred",
              'Sleeping: 4.00 s',
              'Retrying... (There are 2 retries left)',
              "#{error_msg} occurred",
              'Sleeping: 8.00 s',
              'Retrying... (There are 1 retries left)',
              "#{error_msg} occurred",
              'No more attempts to connect will be made'
            ]
          end

          let(:expected_total_time) { 14.seconds }

          it_behaves_like 'Client re-raising an error'
        end

        context "when specifying the 'geometric' wait strategy" do
          context "with the 'max_attempts' parameter" do
            let(:client) do
              client_factory.create(max_attempts: max_attempts, wait_strategy: :geometric)
            end

            let(:max_attempts) { 3 }

            let(:expected_log) do
              [
                "#{error_msg} occurred",
                'Sleeping: 2.00 s',
                'Retrying... (There are 2 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 4.00 s',
                'Retrying... (There are 1 retries left)',
                "#{error_msg} occurred",
                'No more attempts to connect will be made'
              ]
            end

            let(:expected_total_time) { 6.seconds }

            it_behaves_like 'Client re-raising an error'
          end

          context "with the 'wait_interval' parameter" do
            let(:client) do
              client_factory.create(wait_interval: wait_interval, wait_strategy: :geometric)
            end

            let(:wait_interval) { 1.5 }

            let(:expected_log) do
              [
                "#{error_msg} occurred",
                'Sleeping: 1.50 s',
                'Retrying... (There are 3 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 2.25 s',
                'Retrying... (There are 2 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 3.38 s',
                'Retrying... (There are 1 retries left)',
                "#{error_msg} occurred",
                'No more attempts to connect will be made'
              ]
            end

            let(:expected_total_time) { 7.seconds }

            it_behaves_like 'Client re-raising an error'
          end
        end

        context "when specifying the 'constant' wait strategy" do
          context "with the 'max_attempts' parameter" do
            let(:client) do
              client_factory.create(max_attempts: max_attempts, wait_strategy: :constant)
            end

            let(:max_attempts) { 3 }

            let(:expected_log) do
              [
                "#{error_msg} occurred",
                'Sleeping: 2.00 s',
                'Retrying... (There are 2 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 2.00 s',
                'Retrying... (There are 1 retries left)',
                "#{error_msg} occurred",
                'No more attempts to connect will be made'
              ]
            end

            let(:expected_total_time) { 4.seconds }

            it_behaves_like 'Client re-raising an error'
          end

          context "with the 'wait_interval' parameter" do
            let(:client) do
              client_factory.create(wait_interval: wait_interval, wait_strategy: :constant)
            end

            let(:wait_interval) { 1.5 }

            let(:expected_log) do
              [
                "#{error_msg} occurred",
                'Sleeping: 1.50 s',
                'Retrying... (There are 3 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 1.50 s',
                'Retrying... (There are 2 retries left)',
                "#{error_msg} occurred",
                'Sleeping: 1.50 s',
                'Retrying... (There are 1 retries left)',
                "#{error_msg} occurred",
                'No more attempts to connect will be made'
              ]
            end

            let(:expected_total_time) { 4.5.seconds }

            it_behaves_like 'Client re-raising an error'
          end
        end
      end
    end
  end

  describe '#delete_by_query' do
    subject(:method_call) { index.delete_by_query(query) }

    let(:index_name) { 'characters_delete_by_query' }

    let(:fixture_file) { Pathname.new(__dir__) / '..' / '..' / 'test_data' / 'characters.json' }
    let(:test_data) { JSON.parse(File.read(fixture_file)) }

    let(:match_all_query) { JayAPI::Elasticsearch::QueryBuilder.new.to_query }

    let(:query_builder) do
      JayAPI::Elasticsearch::QueryBuilder.new.tap do |builder|
        builder.query.match_phrase(field: 'element.keyword', phrase: 'Anemo')
      end
    end

    let(:query) { query_builder.to_query }

    before do
      index.delete_by_query(match_all_query) if client.transport_client.indices.exists(index: index_name)

      test_data.each do |document|
        index.push(document)
      end

      index.flush
      sleep 4
    end

    it 'deletes the expected number of items from the index' do
      expect do
        method_call
        sleep 2 # Elasticsearch takes some time to process the deletion, it seems
      end.to(
        change { index.search(match_all_query).total }.by(-2)
      )
    end

    it 'returns the expected Hash' do
      # Only elements whose values are certain are probed.
      expect(method_call).to include(
        timed_out: false,
        total: 2,
        deleted: 2,
        failures: []
      )

      # For the rest only their presence is checked
      expect(method_call.keys).to include(
        *%i[took version_conflicts batches retries throttled_millis requests_per_second throttled_until_millis]
      )
    end
  end
end
