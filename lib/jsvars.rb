require 'json'

module Jsvars
    def self.included(base)
        base.send(:include, InstanceMethods)
    end

    module InstanceMethods
        def jsvars
            @jsvars = @jsvars || Hash.new
        end        

        def include_jsvars
            jsvars = @jsvars
            name = 'jsvars'
            return unless jsvars
            close_tag_index = response.body.index /<\/body>/i
            js_assignments = []
            jsvars.each do |variable, value|
            js_assignments <<
                if variable.to_s[/\./]
                    "#{ variable } = #{ value.to_json };"
                else
                    "if (typeof(#{ variable }) === 'object') {
                        jsvars.objExtend(#{ variable }, #{ value.to_json });
                    }
                    else {
                        var #{ variable } = #{ value.to_json };
                    }"    
                end
            end
            
            methods = 
            '
            var jsvars = {
                    objExtend: function (mainObject) {
                        for (var i = 1; i < arguments.length; i += 1) {
                            for (prop in arguments[i]){
                                if (arguments[i].hasOwnProperty(prop)) {
                                    mainObject[prop] = (arguments[i][prop]);
                                }
                            }
                        }
                        return mainObject;	
                    }
                }
            '
            methods = methods.gsub(/\n|\r|\t/, ' ').squeeze(' ')

            added_HTML = 
"<!-- added by the #{ name } plugin -->
    <script type='text/javascript'>
        #{ methods } 
        #{ js_assignments.join } 
    </script>
<!-- end #{ name } plugin code -->"
                    
            response.body.insert close_tag_index, added_HTML if close_tag_index
        end            
    end
end
