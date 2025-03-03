###################################################
# REST APIs
###################################################

$Params = @{
    Uri = 'https://api.github.com/events'
    Method = 'Get'
  }
  Invoke-RestMethod @Params                                   # Call a REST API, using the HTTP GET method