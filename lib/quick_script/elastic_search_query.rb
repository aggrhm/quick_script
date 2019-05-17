module QuickScript

  class ElasticSearchQuery

    def initialize(opts={})
      @q = {sort: [], query:{bool: {must: [], should: [], filter: [], must_not: []}}, size: 50}
      @qb = @q[:query][:bool]
      @qbm = @qb[:must]
      @qbf = @qb[:filter]
      @qbs = @qb[:should]
      @qbmn = @qb[:must_not]
      @qs = @q[:sort]
      @page = 1
      @selector_map = {}.with_indifferent_access
      @selector_map[:must] = @qbm
      @selector_map[:should] = @qbs
      @selector_map[:filter] = @qbf
      @selector_map[:must_not] = @qbmn
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
      return 0 if self.size == 0
      return (count / self.size.to_f).ceil
    end

    def bool
      return @qb
    end

    def selector_map
      @selector_map
    end

    def bool_selector_for(sel)
      ret = selector_map[sel]
      ret = @qbf if ret.nil?
      return ret
    end

    def add_clause(sel, type, opts)
      qbl = bool_selector_for(sel)
      c = {type => opts}
      qbl << c
      return c
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

    def add_match_filter(field, val, opts={})
      tq = {:match => {}}
      tq[:match][field] = opts.merge(query: val)
      @qbf << tq
    end

    def add_term(bq, field, val)
      if val.is_a?(Array)
        bq << {:terms => {field => val}}
      else
        bq << {:term => {field => val}}
      end
    end

    def add_term_filter(field, val)
      self.add_term(@qbf, field, val)
    end
    def add_term_should(field, val)
      self.add_term(@qbs, field, val)
    end

    def add_nested_filter(path, opts={})
      q = {nested: {path: path, query: {bool: {must: []}}}}
      fq = q[:nested][:query][:bool][:must]
      yield fq
      @qbf << q
    end

    def add_simple_query_string(fields, query, opts={})
      analyzer = opts[:analyzer] || "english"
      sqs = {
        query: query,
        fields: fields,
        default_operator: "and"
      }
      sqs[:analyzer] = opts[:analyzer] if opts[:analyzer]
      @qbm << {
        simple_query_string: sqs
      }
    end

    def add_range_filter(field, range)
      @qbf << {:range => {field => range}}
    end

    def add_filter(type, opts)
      @qbf << {type => opts}
    end

    def add_must(type, opts)
      @qbm << {type => opts}
    end

    def add_should(type, opts)
      @qbs << {type => opts}
    end

    def add_must_not(type, opts)
      @qbmn << {type => opts}
    end

    def add_parsed_scope(key, val)
      if key.start_with?("with_")
        self.add_term_filter(key[5..-1], val)
      elsif key.start_with?("search_")
        self.add_match_filter(key[7..-1], val)
      elsif key.start_with?("has_")
        self.add_term_filter(key, val)
      elsif key == "sort"
        fld,ord = val.split(" ")
        self.add_sort(fld, ord)
      end
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
      elsif field.is_a?(String)
        fld, ord = field.split(" ")
        @qs << {fld => ord}
      else
        @qs << field
      end
    end

    def ensure_array(arr)
      if arr.is_a?(Array)
        return arr
      else
        return [arr]
      end
    end

  end

end
