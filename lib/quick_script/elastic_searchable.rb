module QuickScript

  module ElasticSearchable

    def self.included(base)
      base.extend ClassMethods
      base.include Elasticsearch::Model
    end

    class SearchContext

      attr_accessor :query, :requested_scope, :requested_aggregations, :requested_includes, :before_query_callback, :after_query_callback

      def before_query(&block)
        @before_query_callback = block
      end
      def after_query(&block)
        @after_query_callback = block
      end

    end

    module ClassMethods

      def search_elastic(opts, &block)
        # setup query
        qc = QuickScript::ElasticSearchable::SearchContext.new
        q = qc.query = QuickScript::ElasticSearchQuery.new
        block.call(qc) if block
        page = opts[:page].present? ? opts[:page].to_i : 1
        limit = opts[:limit].present? ? opts[:limit].to_i : 50
        offset = (page-1) * limit
        q.from = offset
        q.size = limit

        qc.requested_scope ||= QuickScript.parse_opts(opts[:scope])
        qc.requested_includes ||= QuickScript.parse_opts(opts[:includes]) || []
        scope = qc.requested_scope
        incls = qc.requested_includes
        if (sort = opts[:sort]).present?
          fld,ord = sort.split(" ")
          q.add_sort(fld, ord)
        end
        aggs = qc.requested_aggregations = QuickScript.parse_opts(opts[:aggregations]) || []

        # aggregations
        aggs.each do |agg|
          ea = {
            terms: {
              field: agg['field'],
              size: agg['size'] || 100
            }
          }
          if agg['filter']
            ea = {
              filter: {term: agg['filter']},
              aggs: {
                filtered: ea
              }
            }
          end
          if agg['nested']
            ea = {
              nested: {path: agg['nested']},
              aggs: {
                nested: ea
              }
            }
          end
          q.add_aggregation(agg['association'], ea)
        end
        
        # process context before query callback
        qc.before_query_callback.call if qc.before_query_callback

        # do search
        puts q.raw_query
        resp = self.search(q.raw_query)
        raw_resp = resp.response
        count = resp.results.total

        # build data
        puts "INCLUDES : #{incls.inspect}"
        resp = qc.after_query_callback.call(resp) if qc.after_query_callback
        models = resp.records.includes(incls).to_a
        ret = {success: true, data: models, count: count, pages_count: q.page_count(count), page: q.page}

        # build aggregations
        ret[:aggregations] = raw_resp['aggregations']
        aggs.each do |agg|
          if agg['class_name'].present?
            an = agg['association']
            ar = ret[:aggregations][an]
            ids = ar['buckets'].collect{|b| b['key']}
            model_class = agg['class_name'].constantize
            ams = model_class.find(ids)
            # sort by ids
            if ams
              ams = ams.sort_by {|m| ids.index(m.id.to_s)}
            end
            ret[an] = ams
          end
        end

        return ret
      end

    end

    def update_elastic(action=:index)
      action = action.to_sym
      case action
      when :delete
        self.__elasticsearch__.delete_document
      else
        self.__elasticsearch__.index_document
      end
    end

  end

end
