/**
 * Created by Michael on 11-07-22.
 */

public with sharing class CV_Intf_WebserviceCalloutDummy extends CV_Intf_WebserviceCalloutAbstract implements CV_Intf_WebserviceCallout{

    @TestVisible
    private static Integer mode = 1;

    private String setInterfaceType() {
        return 'TEST';
    }

    private String setNamedCredential() {
        return 'testCallout';
    }

    private String setCaller() {
        return 'CV_Intf_WebserviceCalloutDummy';
    }

    private Boolean setQueueing() {
        return false;
    }

    private Integer setMode() {
        return mode;
    }

    private String setMethod() {
        return 'POST';
    }
    private Map<String, String> setHeaders() {
        return new Map<String, String>();
    }
    private Map<String, String> setTagRemap() {
        return new Map<String, String>();
    }

    public void executeCallout(List<Object> payloadObjects) {

        super.doCallout(payloadObjects);
    }

    public void handleResponse(CV_Intf_ServiceResult serviceResult, String payload, Boolean technicalError) {
    }

    public void registerMonitoningMessage(String outgoingMessage, String responseMessage, String interfaceName, Integer statusCode, Boolean isError, Boolean isResponse) {
        super.registerMonitoningMessage(outgoingMessage, responseMessage, interfaceName, statusCode, isError, '12456454arekzlhjvhieiedfffhesds', true);
    }

}