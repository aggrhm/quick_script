module QuickScript

  module OAuth2

    module Interaction

      def self.included(base)
        if base.respond_to?(:helper_method)
          base.helper_method :is_logged_in? 
          base.helper_method :current_user_data
        end
      end

      def is_logged_in?
        session[:token_data] != nil
      end

      def is_token_expired?
        t = session[:token_expires_at]
        return true if t.nil?
        return Time.now > t
      end

      def api_request(method, path, params={}, opts={})
        hdrs = opts[:headers] || {}
        if is_logged_in?
          access_token = current_user_access_token
          hdrs['Authorization'] = "Bearer " + access_token
        end
        hdrs['API-Version'] = "2"
        url = "/api/#{path}"
        puts "URL: #{url}"
        puts "PARAMS: #{params}"
        # parse params
        params.each do |k, v|
          if v.is_a?(ActionDispatch::Http::UploadedFile)
            params[k] = Faraday::UploadIO.new(v.tempfile, v.content_type, v.original_filename)
          end
        end
        return case method.downcase.to_sym
        when :get
          api_connection.get(url, params, hdrs)
        when :post
          api_connection.post(url, params, hdrs)
        when :delete
          api_connection.delete(url, params, hdrs)
        end
      end

      def api_authenticate(params)
        if params[:grant_type].blank?
          params[:grant_type] = 'password' if params.key?(:password)
          params[:grant_type] = 'refresh_token' if params.key?(:refresh_token)
          params[:grant_type] = 'authorization_code' if params.key?(:code)
        end
        resp = api_connection.post("/auth/token", params)
        token = nil
        if resp.status == 200
          token = JSON.parse(resp.body)
        else
          begin
            Rails.logger.info JSON.parse(resp.body).inspect
          rescue
          end
          return false
        end
        api_set_token(token)
        return true
      end

      def api_set_token(token) 
        session[:token_data] = token
        session[:token_expires_at] = Time.at(Time.now.utc.to_i + token["expires_in"])
      end 
      
      def api_refresh_token
        return api_authenticate(refresh_token: session[:token_data]['refresh_token'])
      end

      def get_current_user_data(opts={})
        return nil if !is_logged_in?
        fields = opts[:fields] || QuickScript.config.default_current_user_session_fields
        resp = api_request(:get, "/account")
        if resp.status == 200
          rd = JSON.parse(resp.body)
          user = rd["data"]
          session[:current_user_data] = user.slice(*fields)
          return user
        else
          return nil
        end
      end

      def current_user_id
        if is_logged_in?
          current_user_data['id']
        else
          return nil
        end
      end

      def current_user_data
        if is_logged_in?
          session[:current_user_data]
        else
          return nil
        end
      end

      def current_user_access_token
        if is_logged_in?
          api_refresh_token if is_token_expired?
          return session[:token_data]['access_token']
        else
          return nil
        end
      end

      def api_connection
        @api_connection ||= Faraday.new(url: APP_CONFIG[:api_host_url], params: {client_id: APP_CONFIG[:client_id], client_secret: APP_CONFIG[:client_secret]}) do |f|
          f.request :multipart
          f.request :url_encoded
          f.adapter Faraday.default_adapter
        end
      end

    end

  end

end
