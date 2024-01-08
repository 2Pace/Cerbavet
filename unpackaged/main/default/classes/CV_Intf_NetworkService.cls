/**
 * Created by Michael on 20-04-22.
 */

public with sharing class CV_Intf_NetworkService {

    public CV_Intf_ServiceResult execute(CV_Intf_RequestInput requestInput) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setTimeout(requestInput.timeout);
        request.setEndpoint(requestInput.urlString);
        request.setMethod(requestInput.method);

        for (String key : requestInput.headers.keySet()) {
            request.setHeader(key, requestInput.headers.get(key));
        }

        switch on requestInput.method {
            when 'GET' {
                request.setBody(buildQueryStrings(requestInput.headers));
            }
            when 'POST' {
                request.setBody(requestInput.parameters);
                request.setTimeout(120000);
                System.debug('=================== Body POST: '+requestInput.parameters);

            }
        }

        HttpResponse response = http.send(request);
        CV_Intf_ServiceResult serviceResult = new CV_Intf_ServiceResult(response.getBody(), response.getStatusCode());

        return serviceResult;
    }


    private String buildQueryStrings(Object parameters) {

        String body = '';

        Map<String, String> mapParams = (Map<String, String>) parameters;

        if(mapParams != null) {
            for (String key : mapParams.keySet()) {
                body += key +'='+ mapParams.get(key) + '&';
            }

            body.removeEnd('&');
        }

        return body;
    }

}