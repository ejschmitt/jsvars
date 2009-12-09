require 'json'

module Jsvars
    def self.included(base)
        base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def jsvars(option = nil)
          @jsvars ||= Hash.new
          if option == false
            @vars_off = true
          end
          @jsvars
      end   

        def include_jsvars
            jsvars = @jsvars
            name = 'jsvars'
            return unless jsvars && response && response.content_type && response.content_type[/html|fbml/i]
            return if @vars_off
            js_assignments = []
            jsvars.each do |variable, value|
                js_assignments <<
                    if variable.to_s[/\./]
                        # allows usage like jsvars['myObj.myVar.myValue'] = "number"
                        object_tests = []
                        objects = variable.split('.') 
                        (0...objects.length - 1).each do |i|
                            object_name = objects[0..i].join('.')
                            object_tests <<
                                "
                                if (#{ object_name } === undefined) {
                                    #{ "var" if i == 0 } #{ object_name } = {};
                                }
                                "
                        end
                        object_tests.join + "#{ variable } = #{ value.to_json };"
                    else
                        "
                        if (typeof(#{ variable }) === 'object') {
                            jsvars.objExtend(#{ variable }, #{ value.to_json });
                        }
                        else {
                            var #{ variable } = #{ value.to_json };
                        }
                        "    
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

            added_script = 
"<!-- added by the #{ name } plugin -->
    <script type='text/javascript'>
        #{ methods } 
        #{ js_assignments.join } 
    </script>
<!-- end #{ name } plugin code -->"

            if index = response.body.index(/<\/body>/i)
                response.body.insert index, added_script
            else
                response.body << added_script
            end
        end            
    end
end



