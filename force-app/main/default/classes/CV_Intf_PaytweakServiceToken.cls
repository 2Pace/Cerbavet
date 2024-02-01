    /**
     * @description       : Class to Paytweak token
     * @author            : Ingrid OMAR
     * @group             : 
     * @last modified on  : 02-01-2024
     * @last modified by  : Ingrid OMAR
    **/
    public with sharing class CV_Intf_PaytweakServiceToken {
        private static String client_secret = System.Label.Intf_PaytweakSecret;
        private static String client_public = System.Label.Intf_PaytweakPublic;
        private static String token_url = System.label.Intf_PaytweakUrl;
        public static string securityToken = '';
        private Static String getSecurityToken() {

            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setHeader('Accept', '*/*');
            req.setHeader('Content-Type','application/json; charset=utf-8');
            req.setHeader('Connection','keep-alive');
            req.setHeader('Paytweak-API-KEY',client_public);
            req.setEndpoint(token_url+'hello');
            system.debug('**** IMA TOKEN URL == ' + token_url + ' / ClientPublic Value == ' + client_public);
            
            Http http = new Http();
            HTTPResponse response = http.send(req);
            
            System.debug('Status ' + response.getStatus());
            System.debug('Status code ' + response.getStatusCode());
            System.debug('HttpRequest' + req);
            
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                String replaceIllegal= response.getbody().replaceAll('\n','').replaceAll('\r','').replaceAll('\t','');
                System.debug('body response == ' + replaceIllegal);
                Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(replaceIllegal);
                securityToken = (String)results.get('Paytweak-Security-Token');
                System.debug('SECURITY TOKEN Value = ' + securityToken);
            }
            return securityToken;
        }

        public Static String getWorkToken() {
            if(CV_BankPaymentOrderService.bypassToken == true){
                return null;
            }
            String securityToken = getSecurityToken();
            System.debug('*** IMA For WorkTk security token value -- ' + securityToken);

            if(securityToken != null && securityToken != ''){
                String workToken; 
                String concatUserToken = securityToken + client_secret;
                String base64Content = EncodingUtil.Base64Encode(Blob.valueOf( concatUserToken ));
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setHeader('Accept', '*/*');
                req.setHeader('Content-Type','application/json; charset=utf-8');
                req.setHeader('Paytweak-USER-TOKEN', base64Content);
                req.setEndpoint(token_url+'verify');
                
                Http http = new Http();
                HTTPResponse response = http.send(req);
                System.debug('Body ' + response.getBody());
                System.debug('Status ' + response.getStatus());
                System.debug('Status code ' + response.getStatusCode());
                
                if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                    Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    workToken = (String)results.get('Paytweak-Work-Token');
                }
                return workToken;
            }
            return null;
        }

    }