/**
 * Created by Michael on 20-04-22.
 */

public with sharing class CV_Intf_RequestInput {

    public String urlString {get; set;}
    public String method  { get; set; }
    public Map<String, String> headers  { get; set; }
    public String parameters  { get; set; }
    public String encoding {get; set;}
    public Integer timeout = 30000;
    public String paytweakWorkToken = CV_Intf_PaytweakServiceToken.getWorkToken();

    // private Map<String, String> defaultHeaders {

    //     get { return new Map<String, String> {'Content-Type' => 'text/xml;charset=UTF-8'}; }//'Content-Type', 'text/xml; charset=character encoding'
    // }

    private Map<String, String> paytweakHeaders {

        get { return new Map<String, String> {'Content-Type' => HttpHexFormBuilder.GetContentType(),
                                              'Paytweak-Token' => paytweakWorkToken }; }//'Content-Type', 'text/xml; charset=character encoding'
    }




    public CV_Intf_RequestInput(String urlString, String method, String parameters) {
        this.urlString = urlString;
        this.method = method;
        this.parameters = parameters;
        this.headers =  this.paytweakHeaders;
    }

}