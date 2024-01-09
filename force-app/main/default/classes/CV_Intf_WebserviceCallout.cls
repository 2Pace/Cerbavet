/**
 * @description       :
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 19-04-2022
 * @last modified by  : Michaël Cabaraux
**/

public interface CV_Intf_WebserviceCallout {

    void executeCallout(List<Object> payloadObjects);
    void handleResponse(CV_Intf_ServiceResult serviceResult, String payload, Boolean technicalError);
    void registerMonitoningMessage(String outgoingMessage, String responseMessage, String interfaceName, Integer statusCode, Boolean isError, Boolean isResponse);

}