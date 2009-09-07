ActionController::Base.send :include, Jsvars
ActionController::Base.send :after_filter, :include_jsvars