/**
 * Created by Michael on 16-06-22.
 */

public with sharing class CV_SalesforceIntegrationError {

    public String errorCode;
    public String message;

    public CV_SalesforceIntegrationError(String errorCode, string message){
        this.errorCode = errorCode;
        this.message = message;
    }

}