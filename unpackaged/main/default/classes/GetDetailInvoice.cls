public class GetDetailInvoice {
    //Apex properties or variables
    ApexPages.StandardController sc;
    public List<Order>  orderList {get; set;}
    public List<OrderItem> ordrItm {get; set;}
    public String accountName { get; set; }
    public String orderName { get; set; }
    public String invoiceNumber { get; set; }
    public String billingStreet { get; set; }
    public String billingCity { get; set; }
    public String billingPostalCode { get; set; }
    public Integer numberOfOrders { get; set; }
    public Decimal discount { get; set; }
    public Decimal totalAmount { get; set; }
    public Decimal totalAmountWithoutTVA { get; set; }
    public Decimal totalAmountWithTVA { get; set; }
    public Decimal TVAAmount { get; set; }
    public Integer shippingCost { get; set; }
    public Integer TVA { get; set; }
    public Case cas { get; set; }
    Public string selectedname{get;set;}
    Public string renderType{get;set;}
    Public string symbol{get;set;}
    Public string conName{get;set;}
    Public string billingCityCode{get;set;}
    Public List<Selectoption> lstnamesel {get; set;}
    //public List<SBQQ__QuoteLine__c> sbQuoteLine {get;set;}
    public List<SBQQ__QuoteLine__c> sbQuoteLineList {get;set;}
    public SBQQ__QuoteLine__c sbQLine {get;set;}
    public SBQQ__QuoteLine__c sbQLineLast {get;set;}
    public list<wrapper> wrp {get;set;}
    
    public String fieldValue {get; set;}
    public String fieldValue2 {get; set;}
    public void passValueToController(){
        fieldValue = selectedname;
        fieldValue2 = selectedname;
        this.testMethods();
    }
    public void renderAsPDF(){
        this.renderType = 'PDF';
    }
    
    //constructor to get the Case record
    public GetDetailInvoice(ApexPages.StandardController sc) {
        testMethods();
    }
    public void testMethods(){
        string invoiceid=ApexPages.currentPage().getParameters().get('id');
        //string invoiceid='a3Y0D000000cgKkUAI';
        system.debug('invoiceid+++>'+invoiceid);
        string accountId = '';
        system.debug('selectedname'+fieldValue);
        String orderProd = '';
        List<String> qLIds = new List<String>();
        List<String> quoteIds = new List<String>();
        map<Id,blng__InvoiceLine__c> qLidToIL = new map<Id,blng__InvoiceLine__c>();
        wrp=new list<wrapper>();
        totalAmount = 0;
        List<blng__InvoiceLine__c> bInvLin = [SELECT Id, blng__Product__r.Name,blng__Quantity__c,blng__Subtotal__c, blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.SBQQ__QuoteLine__c,blng__Invoice__c,blng__Invoice__r.blng__Account__c FROM blng__InvoiceLine__c where blng__Invoice__c =:invoiceid];
        if(bInvLin.size()>0){
            for(blng__InvoiceLine__c invLin: bInvLin){
                
                totalAmount +=invLin.blng__Subtotal__c; 
                system.debug('first');
                List<SBQQ__QuoteLine__c> sbQuoteLine = [SELECT Id, SBQQ__Number__c, SBQQ__Quote__c, Date_Session__c ,SBQQ__NetPrice__c,SBQQ__Quantity__c , SBQQ__NetTotal__c, SBQQ__Product__c, SBQQ__ProductName__c, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c where SBQQ__RequiredBy__c =:invLin.blng__OrderProduct__r.SBQQ__QuoteLine__c order by SBQQ__Number__c];
                
                wrapper wrpr = new wrapper();
                wrpr.Inline = invLin;
                wrpr.Qtline = sbQuoteLine; 
                
                wrp.add(wrpr);
                
                orderProd=invLin.blng__OrderProduct__r.OrderId;
            }
        }
        
        system.debug('wrpr===>'+wrp);
        List<OrderItem> oItm= [SELECT OrderId,Order.OrderNumber, Id, Product2Id FROM OrderItem where OrderId =:orderProd];
        
        List<blng__Invoice__c> blngInvoice= [SELECT Id, Name, blng__Account__r.Name FROM blng__Invoice__c where id =: invoiceid];
        
        TVA = 20;
        totalAmountWithTVA = totalAmount*TVA/100;
        TVAAmount = totalAmount + totalAmountWithTVA;
        accountName = blngInvoice[0].blng__Account__r.Name;
        invoiceNumber = blngInvoice[0].Name;
        orderName = oItm[0].Order.OrderNumber;
        symbol = getCurrencySymbol();
    }
    public static String getCurrencyIsoCode(){
        String currencyIso =  UserInfo.getDefaultCurrency();
        return currencyIso;
    }
    
    public static String getCurrencySymbol() {
        return getCurrencySymbolFromIso(getCurrencyIsoCode());
    }
    
    public static String getCurrencySymbolFromIso(String Iso) {
        String currencySymbol = 
            ('USD' == Iso ? '$' : 
             ('CAD' == Iso ? '$' : 
              ('EUR' == Iso ? '€' : 
               ('GBP' == Iso ? '£' : 
                ('JPY' == Iso ? '¥' : 
                 ('KRW' == Iso ? '₩' : 
                  ('CNY' == Iso ? '元' : 
                   Iso)))))));
        system.debug('currencySymbol'+currencySymbol);
        return currencySymbol;
    }
    public class wrapper{
        public blng__InvoiceLine__c Inline{get;set;}
        public List<SBQQ__QuoteLine__c> Qtline{get;set;}
    }
}