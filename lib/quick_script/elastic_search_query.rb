module QuickScript

  class ElasticSearchQuery

    def initialize(opts={})
      @q = {sort: [], query:{bool: {must: [], filter: []}}, size: 50}
      @qb = @q[:query][:bool]
      @qbm = @qb[:must]
      @qbf = @qb[:filter]
      @qs = @q[:sort]
      @page = 1
    end

    def raw_query
      @q
    end

    def page=(val)
      @page = val
      self.from = (@page - 1) * self.size
      @page
    end

    def page
      @page
    end

    def from=(val)
      @q[:from] = val
    end

    def from
      @q[:from]
    end

    def size=(val)
      @q[:size] = val
    end

    def size
      @q[:size]
    end

    def limit=(val)
      self.size=(val)
    end

    def limit
      return self.size
    end

    def page_count(count)
      return (count / self.size.to_f).ceil
    end

    def add_multimatch_query(fields, val, type=nil)
      type ||= 'best_fields'
      @qbm << {:multi_match => {
        query: val,
        fields: fields,
        type: type
      }}
    end

    def add_match_query(field, val)
      tq = {:match => {}}
      tq[:match][field] = val
      @qbm << tq
    end

    def add_term_filter(field, val)
      if val.is_a?(Array)
        @qbf << {:terms => {field => val}}
      else
        @qbf << {:term => {field => val}}
      end
    end

    def add_range_filter(field, range)
      @qbf << {:range => {field => range}}
    end

    def add_match_filter(field, val)
      @qbf << {:match => {field => val}}
    end

    def add_aggregation(name, aopts)
      self.aggs[name] = aopts
    end

    def aggs
      @q[:aggregations] ||= {}
      return @q[:aggregations]
    end

    def add_sort(field, order=nil)
      if order
        @qs << {field => order}
      else
        @qs << field
      end
    end

  end

end
