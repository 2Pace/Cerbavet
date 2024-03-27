/**
 * Created by Michael on 20-04-22.
 */

public with sharing class CV_Intf_ServiceResult {

    public Boolean isSuccess {get; set;}
    public string body {get; set;}
    public String errorType {get; set;}
    public Integer statusCode {get; set;}

    public CV_Intf_ServiceResult(string body, Integer statusCode) {
        this.body = body;
        this.isSuccess = body != null;
        this.statusCode = statusCode;

        system.debug('**** IMA CV_Intf_ServiceResult body ==  ' + this.body);
    }

}