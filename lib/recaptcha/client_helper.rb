module Recaptcha
  module ClientHelper
    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      # Default options
      key   = options[:public_key] ||= Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless key
      error = options[:error] ||= ((defined? flash) ? flash[:recaptcha_error] : "")
      uri   = Recaptcha.configuration.api_server_url(options[:ssl])
      lang  = options[:display] && options[:display][:lang] ? options[:display][:lang].to_sym : ""
      html  = ""
      if options[:display]
        html << %{<script type="text/javascript">\n}
        html << %{  var RecaptchaOptions = #{hash_to_json(options[:display])};\n}
        html << %{</script>\n}
      end
      if options[:ajax]
        if options[:display] && options[:display][:custom_theme_widget]
          widget = options[:display][:custom_theme_widget]
        else
          widget = "dynamic_recaptcha"
          html << <<-EOS
           <div id="#{widget}"></div>
          EOS
        end
        html << <<-EOS
          <script type="text/javascript">
            var rc_script_tag = document.createElement('script'),
                rc_init_func = function(){Recaptcha.create("#{key}", document.getElementById("#{widget}")#{',RecaptchaOptions' if options[:display]});}
            rc_script_tag.src = "#{uri}/js/recaptcha_ajax.js";
            rc_script_tag.type = 'text/javascript';
            rc_script_tag.onload = function(){rc_init_func.call();};
            rc_script_tag.onreadystatechange = function(){
              if (rc_script_tag.readyState == 'loaded' || rc_script_tag.readyState == 'complete') {rc_init_func.call();}
            };
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(rc_script_tag);
          </script>
        EOS
      else

        if options[:display] && options[:display][:theme] == 'custom'

          # Prints raw HTML Recaptcha widget so that it may be styled via CSS
          # More info: https://developers.google.com/recaptcha/docs/customization?csw=1

          widget = options[:display][:custom_theme_widget] || 'recaptcha_widget'
          html << <<-EOS
            <div id="recaptcha_widget" style="display:none" class="recaptcha_widget">
              <div id="recaptcha_image"></div>
              <div class="recaptcha_footer">
                <div class="recaptcha_input">
                  <label class="recaptcha_only_if_image recaptcha_hide" for="recaptcha_response_field">Enter the words above:</label>
                  <label class="recaptcha_only_if_audio recaptcha_hide" for="recaptcha_response_field">Enter the numbers you hear:</label>
                  <input type="text" id="recaptcha_response_field" name="recaptcha_response_field" autocomplete="off" placeholder="Prove you're a human!" class="text">
                </div>
                <div class="recaptcha_buttons">
                  <div class="recaptcha_btn">
                    <a class="refresh_icon" href="javascript:Recaptcha.reload()">Get another CAPTCHA</a>
                  </div>
                  <div class="recaptcha_only_if_image recaptcha_btn">
                    <a class="audio_icon" href="javascript:Recaptcha.switch_type('audio')">Get an audio CAPTCHA</a>
                  </div>
                  <div class="recaptcha_only_if_audio recaptcha_btn">
                    <a class="text_icon" href="javascript:Recaptcha.switch_type('image')">Get an image CAPTCHA</a>
                  </div>
                  <div class="recaptcha_btn">
                    <a class="help_icon" href="javascript:Recaptcha.showhelp()">Help</a>
                  </div>
                </div>
              </div>
            </div>
          EOS
        end
        html << %{<script type="text/javascript" src="#{uri}/challenge?k=#{key}}
        html << %{#{error ? "&amp;error=#{CGI::escape(error)}" : ""}}
        html << %{#{lang ? "&amp;lang=#{lang}" : ""}"></script>\n}
        unless options[:noscript] == false
          html << %{<noscript>\n  }
          html << %{<iframe src="#{uri}/noscript?k=#{key}" }
          html << %{height="#{options[:iframe_height] ||= 300}" }
          html << %{width="#{options[:iframe_width]   ||= 500}" }
          html << %{style="border:none;"></iframe><br/>\n  }
          html << %{<textarea name="recaptcha_challenge_field" }
          html << %{rows="#{options[:textarea_rows] ||= 3}" }
          html << %{cols="#{options[:textarea_cols] ||= 40}"></textarea>\n  }
          html << %{<input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>}
          html << %{</noscript>\n}
        end
      end
      return (html.respond_to?(:html_safe) && html.html_safe) || html
    end # recaptcha_tags

    private

    def hash_to_json(hash)
      result = "{"
      result << hash.map do |k, v|
        if v.is_a?(Hash)
          "\"#{k}\": #{hash_to_json(v)}"
        elsif ! v.is_a?(String) || k.to_s == "callback"
          "\"#{k}\": #{v}"
        else
          "\"#{k}\": \"#{v}\""
        end
      end.join(", ")
      result << "}"
    end
  end # ClientHelper
end # Recaptcha
