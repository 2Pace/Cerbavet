/**
 * @description       :
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-05-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_WebserviceCalloutService {

    private static List<CV_Intf_WebserviceCalloutService.ResponseModel> responses = new List<CV_Intf_WebserviceCalloutService.ResponseModel>();

    @future(callout=true)
    public static void fireFutureCallout(String jsonPayload, String namedCredential, String caller, String interfaceName, Map<String, String> headers, Map<String, String> tagRemap, String method) {

        CV_Intf_WebserviceCallout instance = (CV_Intf_WebserviceCallout)Type.forName(caller).newInstance();

        List<String> payloads = (List<String>)JSON.deserialize(jsonPayload, List<String>.class);

        for (String payload : payloads) {
            String remappedPayload = remapTagInPayload(payload, tagRemap);

            calloutWebservice(remappedPayload, namedCredential, caller, interfaceName, headers, method);
        }

        for (CV_Intf_WebserviceCalloutService.ResponseModel responseModel : responses) {
            instance.handleResponse(responseModel.serviceResult, responseModel.payload, responseModel.isTechnicalError);
            instance.registerMonitoningMessage(responseModel.payload, responseModel.responseMessage, interfaceName, responseModel.statusCode, responseModel.isError, false);
        }
    }

    public static List<CV_Intf_WebserviceCalloutService.ResponseModel> calloutWebserviceBatch(String jsonPayload, String namedCredential, String caller, String interfaceName, Map<String, String> headers, String method) {

        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebserviceBatch callout Webservice Batch !!:' + namedCredential);

        calloutWebservice(jsonPayload, namedCredential, caller, interfaceName, headers, method);

        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebserviceBatch:' + responses);

        return responses;

    }

    public static void calloutWebservice(String jsonPayload, String namedCredential, String caller, String interfaceName, Map<String, String> headers, String method) {

        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice namedCredential:' + namedCredential);
        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice jsonPayload:' + jsonPayload);

        Boolean isError = true;
        Boolean isTechnicalError = false;
        String responseMessage;
        Integer statusCode;
        CV_Intf_RequestInput requestInput;

        if(interfaceName == 'PAYTWEAK'){
            String bodyPayload = jsonPayload;
            requestInput = new CV_Intf_RequestInput('callout:' +namedCredential, method, bodyPayload,interfaceName);
        } else {
            requestInput = new CV_Intf_RequestInput('callout:' +namedCredential, method, jsonPayload,interfaceName);
        }

        
        if (headers != null && !headers.isEmpty()) {
            requestInput.headers = headers;
        }

        CV_Intf_NetworkService network = new CV_Intf_NetworkService();
        CV_Intf_ServiceResult serviceResult;

        try {
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice requestInput:' + requestInput);
            serviceResult = network.execute(requestInput);
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice serviceResult:' + serviceResult);

            responseMessage = serviceResult.body;
            statusCode = serviceResult.statusCode;
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice responseMessage:' + responseMessage);

            if ((serviceResult.statusCode == 200) || (serviceResult.statusCode == 201)) {
                if (serviceResult.isSuccess) {
                    isError = false;

                }
            } else {
                isTechnicalError = true;
            }
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice isError:' + isError);
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice isTechnicalError:' + isTechnicalError);

        } catch (Exception e) {
            isError = true;
            isTechnicalError = true;
            responseMessage = e.getMessage();
            statusCode = 999;

            serviceResult = new CV_Intf_ServiceResult(responseMessage, statusCode);
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice Exception serviceResult:' + serviceResult);
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice Exception e:' + e.getMessage());

        }

        CV_Intf_WebserviceCallout instance = (CV_Intf_WebserviceCallout)Type.forName(caller).newInstance();
        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice System.isFuture():' + System.isFuture());
        System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice System.isBatch():' + System.isBatch());

        if (!System.isFuture() && !System.isBatch()) {
            instance.handleResponse(serviceResult, jsonPayload, isTechnicalError);
            instance.registerMonitoningMessage(jsonPayload, responseMessage, interfaceName, statusCode, isError, false);
            System.debug('==============================  CV_Intf_WebserviceCalloutService !System.isFuture() && !System.isBatch()');

        } else {
            responses.add(new CV_Intf_WebserviceCalloutService.ResponseModel(responseMessage, jsonPayload, statusCode, isTechnicalError, isError, serviceResult));
            System.debug('==============================  CV_Intf_WebserviceCalloutService calloutWebservice callout ELSE of (!System.isFuture() && !System.isBatch())');
        }
    }

    public static String remapTagInPayload(String serializedPayload, Map<String, String> tagRemap) {

        String remappedString = serializedPayload;

        if (tagRemap!= null && !tagRemap.isEmpty()) {
            for (String origTag : tagRemap.keySet()) {

                String replacingTag = tagRemap.get(origTag);
                remappedString = remappedString.replace(origTag, replacingTag);
            }
        }

        System.debug('============================ CV_Intf_WebserviceCalloutAbstract remapTagInPayload remappedString: ' + remappedString);
        return remappedString;
    }

    public class ResponseModel {

        public Boolean isTechnicalError { get; set; }
        public Boolean isError { get; set; }
        public String responseMessage { get; set; }
        public String payload { get; set; }
        public Integer statusCode { get; set; }
        public CV_Intf_ServiceResult serviceResult { get; set; }

        public responseModel(String responseMessage, String payload, Integer statusCode, Boolean isTechnicalError, Boolean isError,  CV_Intf_ServiceResult serviceResult) {
            this.isError = isError;
            this.isTechnicalError = isTechnicalError;
            this.responseMessage = responseMessage;
            this.statusCode = statusCode;
            this.payload = payload;
            this.serviceResult = serviceResult;
        }
    }

}