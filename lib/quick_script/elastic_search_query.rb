module QuickScript

  class ElasticSearchQuery

    def initialize(opts={})
      @q = {query:{bool: {must: [], filter: {}}}, size: 50}
      @qb = @q[:query][:bool]
      @qbm = @qb[:must]
      @qbf = @qb[:filter]
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

    def add_multimatch_query(fields, val)
      @qbm << {:multi_match => {
        query: val,
        fields: fields
      }}
    end

    def add_match_query(field, val)
      tq = {:match => {}}
      tq[:match][field] = val
      @qbm << tq
    end

    def add_term_filter(field, val)
      @qbf[:and] = [] if !@qbf[:and].present?
      if val.is_a?(Array)
        @qbf[:and] << {:terms => {field => val}}
      else
        @qbf[:and] << {:term => {field => val}}
      end
    end

    def add_match_filter(field, val)
      @qbf[:and] = [] if !@qbf[:and].present?
      @qbf[:and] << {:match => {field => val}}
    end 

    def aggs
      @q[:aggregations] ||= {}
      return @q[:aggregations]
    end

  end

end
