# frozen_string_literal: true

module JayAPI
  module Elasticsearch
    class Stats
      class Index
        # Contains information about an index's totals (docs, used space, etc).
        class Totals
          # @param [Hash] data The data under the index's +total+ key.
          def initialize(data)
            @data = data
          end

          # @return [Integer] The total number of documents in the index.
          def docs_count
            @docs_count ||= docs.fetch('count')
          end

          # @return [Integer] The total number of deleted documents in the index.
          def deleted_docs
            @deleted_docs ||= docs.fetch('deleted')
          end

          # @return [Float] A number between 0 and 1 that represents the ratio
          #   of between deleted documents and total documents in the index.
          def deleted_ratio
            @deleted_ratio ||= calculate_deleted_ratio
          end

          private

          attr_reader :data

          # @return [Hash] The information about the documents in the index.
          #   Looks something like this:
          #
          #   { "count" => 530626, "deleted" => 11 }
          #
          # @raise [KeyError] If the given data doesn't have a +docs+ key.
          def docs
            @docs ||= data.fetch('docs')
          end

          # @return [Float] A number between 0 and 1 that represents the ratio
          #   of between deleted documents and total documents in the index.
          def calculate_deleted_ratio
            if docs_count.zero?
              return deleted_docs.zero? ? 0.0 : 1.0
            end

            deleted_docs / docs_count.to_f
          end
        end
      end
    end
  end
end
