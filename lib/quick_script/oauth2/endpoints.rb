module QuickScript

  module OAuth2

    module Endpoints

      def route_api_request
        path = params[:path]

        resp = api_request(request.method, path, request.query_parameters.merge(request.request_parameters))
        render json: resp.body, status: resp.status
      end

      def account 
        user = get_current_user_data
        if !user.nil? 
          render_result success: true, data: user
        else 
          render_result success: false, data: nil
        end
      end 
      
      def account_login
        # try to get token from API
        if !api_authenticate(params)
          render_result success: false, error: "Your login and password could not be authenticated."
          return
        end
        # get current user and set in session
        user = get_current_user_data
        if user.nil?
          render_result success: false, error: "The user information could not be loaded."
        else
          render_result success: true, data: user
        end
      end

      def account_register
        # create new account
        email = params[:email]
        pw = params[:password]
        resp = api_request(:post, "/account/register", params)
        if resp.status != 200
          render json: resp.body, status: resp.status
          return
        else
          # account registered, login and return account data
          if !api_authenticate({username: email, password: pw})
            render_result success: false, error: "Your account was created but was not properly logged in. Please log in at the sign in page."
            return
          end
          user = get_current_user_data
          render_result success: true, data: user
        end
      end

      def logout
        reset_session
        redirect_to "/"
      end

    end

  end

end
