/**
 * @description       : Class to Paytweak token
 * @author            : Ingrid OMAR
 * @group             : 
 * @last modified on  : 02-01-2024
 * @last modified by  : Ingrid OMAR
**/
public with sharing class CV_Intf_ServiceToken {
    private static String client_secret = System.Label.Intf_PaytweakSecret;
    private static String client_public = System.Label.Intf_PaytweakPublic;
    private static String token_url = System.label.Intf_PaytweakUrl;
    
    private Static String getSecurityToken() {
        if (Test.isRunningTest() ){
            return null;
        }

        String securityToken; 
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json; charset=utf-8');
        req.setHeader('Paytweak-API-KEY', client_public);
        req.setEndpoint(token_url);
        Http http = new Http();
        HTTPResponse response = http.send(req);
        System.debug('Status ' + response.getStatus());
        System.debug('Status code ' + response.getStatusCode());
        Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
            securityToken = (String)results.get('Paytweak-Security-Token');
        }
        return securityToken;
    }

    public Static String getWorkToken() {
        if (Test.isRunningTest() ){
            return null;
        }

        String securityToken = getSecurityToken();

        if(securityToken != null && securityToken != ''){
            String workToken; 
            String concatUserToken = securityToken + client_secret;
            String base64Content = EncodingUtil.Base64Encode(Blob.valueOf( concatUserToken ));
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json; charset=utf-8');
            req.setHeader('Paytweak-USER-TOKEN', base64Content);
            req.setEndpoint(token_url);
            
            Http http = new Http();
            HTTPResponse response = http.send(req);
            System.debug('Body ' + response.getBody());
            System.debug('Status ' + response.getStatus());
            System.debug('Status code ' + response.getStatusCode());
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                workToken = (String)results.get('Paytweak-Work-Token');
            }
            return workToken;
        }
        return null;
    }

}