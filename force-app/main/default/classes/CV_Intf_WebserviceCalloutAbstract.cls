/**
 * @description       :
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-05-2022
 * @last modified by  : Michaël Cabaraux
 * Ver   Date         Author              Modification
 * 1.0   19-05-2017   Michael Cabaraux   Initial Version
**/

public abstract class CV_Intf_WebserviceCalloutAbstract {

    public static final Integer MODE_DIRECT = 1;
    public static final Integer MODE_FUTURE = 2;

    private String interfaceType = setInterfaceType();
    private String namedCredential = setNamedCredential();
    private String caller = setCaller();
    private Integer mode = setMode();
    private Map<String, String> headers = setHeaders();
    private Map<String, String> tagRemap = setTagRemap();
    private String method = setMethod();

    private abstract String setInterfaceType();
    private abstract String setNamedCredential();
    private abstract String setCaller();
    private abstract Integer setMode();
    private abstract String setMethod();
    private abstract Map<String, String> setHeaders();
    private abstract Map<String, String> setTagRemap();


    public void doCallout(List<Object> objectPayloads) {
        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout Object Payloads: ' + objectPayloads);
        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout mode: ' + mode);

        if (!objectPayloads.isEmpty()) {
            switch on mode {
                when 1 {
                    // Direct
                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout Direct calls !!!');
                    List<CV_Intf_WebserviceCalloutService.ResponseModel> responses = new List<CV_Intf_WebserviceCalloutService.ResponseModel>();

                    for (Object payload : objectPayloads) {
                        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout System.objectPayloads.size(): ' + objectPayloads.size());

                        String serializedPayload = CV_Intf_WebserviceCalloutService.remapTagInPayload(JSON.serialize(payload), tagRemap);

                        if (System.isBatch()) {
                            System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout Batch initiated');
                            responses = CV_Intf_WebserviceCalloutService.calloutWebserviceBatch(serializedPayload, namedCredential, caller, interfaceType, headers, method);

                        } else {
                            System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout direct sending no batch');
                            CV_Intf_WebserviceCalloutService.calloutWebservice(serializedPayload, namedCredential, caller, interfaceType, headers, method);
                        }
                    }

                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout System.isBatch(): ' + System.isBatch());
                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout responses: ' + responses);

                    if (System.isBatch() && !responses.isEmpty()) {
                        CV_Intf_WebserviceCallout instance = (CV_Intf_WebserviceCallout)Type.forName(caller).newInstance();

                        for (CV_Intf_WebserviceCalloutService.ResponseModel responseModel : responses) {
                            instance.handleResponse(responseModel.serviceResult, responseModel.payload, responseModel.isTechnicalError);
                            instance.registerMonitoningMessage(responseModel.payload, responseModel.responseMessage, interfaceType, responseModel.statusCode, responseModel.isError, false);
                        }
                    }
                }
                when 2 {
                    // Future
                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout Direct future calls !!! ');


                    //Slicing needed
                    List<List<String>> slicedPayloads = sliceListObjects(objectPayloads, 90);

                    for (List<String> payloads : slicedPayloads)  {
                        String serializedPayloads = JSON.serialize(payloads);
                        CV_Intf_WebserviceCalloutService.fireFutureCallout(serializedPayloads, namedCredential, caller, interfaceType, headers, tagRemap, method);

                    }
                }
            }
        }
    }

    public void doCalloutPaytweak(List<String> bodyPayloadPaytweak) {
        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak bodyPayloadPaytweak : ' + bodyPayloadPaytweak);
        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak mode: ' + mode);

        if (!bodyPayloadPaytweak.isEmpty()) {
            switch on mode {
                when 1 {
                    // Direct
                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak Direct calls !!!');
                    List<CV_Intf_WebserviceCalloutService.ResponseModel> responses = new List<CV_Intf_WebserviceCalloutService.ResponseModel>();
                    for (String payload : bodyPayloadPaytweak) {
                        System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCallout System.bodyPayloadPaytweak.size(): ' + bodyPayloadPaytweak.size());
                        
                        if (System.isBatch()) {
                            System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak Batch initiated');
                            responses = CV_Intf_WebserviceCalloutService.calloutWebserviceBatch(payload, namedCredential, caller, interfaceType, headers, method);

                        } else {
                            System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak direct sending no batch');
                            CV_Intf_WebserviceCalloutService.calloutWebservice(payload, namedCredential, caller, interfaceType, headers, method);
                        }   
                    }

                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak System.isBatch(): ' + System.isBatch());
                    System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak responses: ' + responses);

                    if (System.isBatch() && !responses.isEmpty()) {
                        CV_Intf_WebserviceCallout instance = (CV_Intf_WebserviceCallout)Type.forName(caller).newInstance();

                        for (CV_Intf_WebserviceCalloutService.ResponseModel responseModel : responses) {
                            instance.handleResponse(responseModel.serviceResult, responseModel.payload, responseModel.isTechnicalError);
                            instance.registerMonitoningMessage(responseModel.payload, responseModel.responseMessage, interfaceType, responseModel.statusCode, responseModel.isError, false);
                        }
                    }
                } when 2 {
                // Future
                System.debug('============================ CV_Intf_WebserviceCalloutAbstract doCalloutPaytweak Direct future calls !!! ');
                for (String payload : bodyPayloadPaytweak) {
                    CV_Intf_WebserviceCalloutService.fireFutureCallout(payload, namedCredential, caller, interfaceType, headers, tagRemap, method);
                }
                }
            }
        }
    }

    public void registerMonitoningMessage(String outgoingMessage, String responseMessage, String interfaceName, Integer statusCode, Boolean isError, String transactionId, Boolean isResponse) {

        Interface_Monitoring__c intfMonitoring = new Interface_Monitoring__c();

        intfMonitoring.Message_Id__c = transactionId;
        intfMonitoring.Interface_Name__c = interfaceName;

        if (!isResponse) {
            intfMonitoring.Outgoing_Message__c = (outgoingMessage!=null && outgoingMessage.length()> 131072) ? outgoingMessage.substring(0, 131071) : outgoingMessage;
            intfMonitoring.Status__c = 'I';
            intfMonitoring.Start_Date__c = System.now();
        }

        intfMonitoring.Response_Message__c = (responseMessage!=null && responseMessage.length()> 131072) ?responseMessage.substring(0, 131071) : responseMessage;
        intfMonitoring.Status_Code__c = String.valueOf(statusCode);
        intfMonitoring.End_Date__c = System.now();

        intfMonitoring.Status__c = isError ? 'Error' : 'Success';

        upsert intfMonitoring Message_Id__c;
    }

    private List<List<String>> sliceListObjects(List<Object> objects, integer maxItems) {

        List<List<String>> slicedList = new List<List<String>>();

        for(Integer i = 0 ; i < (objects.size() / maxItems) + 1 ; i++){
            List<String> lstTemp = new List<String>();
            for(Integer j=(i * maxItems); (j < (i * maxItems)+ maxItems) && j < objects.size(); j++){
                lstTemp.add(JSON.serialize(objects.get(j)));
            }
            slicedList.add(lstTemp);
        }

        System.debug('============================ CV_Intf_WebserviceCalloutAbstract sliceListObjects slicedList: ' + slicedList);

        return slicedList;
    }

    private List<List<String>> sliceListString(List<String> stringBody, integer maxItems) {

        List<List<String>> slicedList = new List<List<String>>();

        for(Integer i = 0 ; i < (stringBody.size() / maxItems) + 1 ; i++){
            List<String> lstTemp = new List<String>();
            for(Integer j=(i * maxItems); (j < (i * maxItems)+ maxItems) && j < stringBody.size(); j++){
                lstTemp.add(JSON.serialize(stringBody.get(j)));
            }
            slicedList.add(lstTemp);
        }

        System.debug('============================ CV_Intf_WebserviceCalloutAbstract sliceListObjects sliceListString: ' + slicedList);

        return slicedList;
    }

}