# =========================
# CLOUDFRONT FUNCTION: Redirect to QA based on ?environment
# =========================
variable "qa_cloudfront_domain" {
  type    = string
  default = "https://dcsivaay3lltb.cloudfront.net/"
}

resource "aws_cloudfront_function" "redirect_env" {
  name    = "redirectEnvironment"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect to QA CloudFront based on ?environment"

  code = <<EOF
function handler(event) {
    var request = event.request;
    var qs = request.querystring;
    var envMap = { "qa": "${var.qa_cloudfront_domain}" };
    if (qs.environment && qs.environment.value) {
        var env = qs.environment.value.toLowerCase();
        if (envMap[env]) {
            var redirectUrl = envMap[env] + request.uri;

            // Preserve other query strings
            var queryParts = [];
            for (var key in qs) {
                if (key !== 'environment') { queryParts.push(key + '=' + qs[key].value); }
            }
            if (queryParts.length > 0) { redirectUrl += '?' + queryParts.join('&'); }

            return {
                statusCode: 302,
                statusDescription: 'Found',
                headers: { "location": { value: redirectUrl } }
            };
        }
    }
    return request;
}
EOF
}
