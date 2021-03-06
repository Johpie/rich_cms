module Rich
  module Cms
    module Auth

      class Adapter

        attr_accessor :current_controller

        delegate :sign_out, :warden, :params, :session, :to => :current_controller
        delegate :klass, :klass_symbol, :current_admin_method, :to => :specs

        def initialize(specs)
          @specs = specs
        end

        def login
          raise NotImplementedError
        end

        def logout
          raise NotImplementedError
        end

        def admin
          raise NotImplementedError
        end

      protected

        attr_accessor :specs

      end

    end
  end
end