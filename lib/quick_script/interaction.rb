module QuickScript
	module Interaction

    ## HELPER ACTIONS
    
    def layout_only
      render :text => '', :layout => 'application'
    end

		protected

		class << self
			def included(base)
				base.send :before_filter, :handle_params if base.respond_to? :before_filter
			end
		end

		class ScopeResponder
			def initialize
				@names = {}
			end
			def respond(scope)
        crit = nil

        if @names['before_filter']
          crit = @names['before_filter'].call
        end

        scope.selectors.each do |k, v|
          if crit.nil?
            crit = @names[k].call(*v)
          else
            crit.merge!(@names[k].call(*v))
          end
        end

        if crit.is_a? Mongoid::Criteria
          crit = crit.limit(scope.limit).offset(scope.offset).to_a
        end
        return crit
			end
			def method_missing(method_sym, *args, &block)
				@names[method_sym.to_s] = block
			end
		end

		def json_resp(data, meta=true, opts = {})
			meta = 200 if meta == true 
			meta = 404 if meta == false 
			opts[:data] = data
			opts[:meta] = meta
			opts.to_json
		end

		def json_error(errors, meta = 404, opts = {})
			json_resp({:errors => errors}, meta, opts)
		end

		def handle_params
      # handle scope
			@scope = {}
			class << @scope
				def selectors; return self[:selectors]; end
				def args; return self[:args]; end
				def limit; return self[:limit]; end
				def page; return self[:page]; end
				def offset; return self[:offset]; end
			end
      if params[:scope]
        if params[:scope].is_a? Array
          @scope[:selectors] = {params[:scope].first => params[:scope][1..-1]}
          @scope[:args] = params[:scope][1..-1]
        else
          # json selectors
          @scope[:selectors] = JSON.parse(params[:scope])
        end
      end
			@scope[:limit] = params[:limit].to_i if params[:limit]
			@scope[:page] = params[:page].to_i if params[:page]
			@scope[:offset] = (@scope[:page] - 1) * @scope[:limit] if params[:page] && params[:limit]

      # handle api_ver
      @api_version = params[:api_ver] ? params[:api_ver].to_i : nil
		end

		def get_scoped_items(model, scope, limit, offset)
				@items = model
				scope.each do |m, args|
					# validate scope
					next unless can? m.to_sym, model
					args = [current_user.id.to_s] if m.include?("my_") && current_user
					if args == []
						@items = @items.send(m)
					else
						@items = @items.send(m, *args)
					end
				end
				return [] if @items == model
				@items = @items.limit(limit).offset(offset)
		end

		def respond_to_scope(&block)
			responder = ScopeResponder.new
			block.call(responder)
			responder.respond @scope
		end

	end
end
