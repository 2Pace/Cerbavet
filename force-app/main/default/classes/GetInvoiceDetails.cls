public class GetInvoiceDetails {
    //Apex properties or variables
    
    public List<Order>  orderList {get; set;}
    public List<OrderItem> ordrItm {get; set;}
    public String accountName { get; set; }
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
    Public string billingCityCode{get;set;}
    Public List<Selectoption> lstnamesel {get; set;}
    
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
    public GetInvoiceDetails(ApexPages.StandardController sc) {
        testMethods();
    }
    public void testMethods(){
        string invoiceid='a3Y0D000000cede';
        //string invoiceid=ApexPages.currentPage().getParameters().get('id');
        system.debug('selectedname'+fieldValue);
        List<String> orderIds = new List<String>();
        List<blng__InvoiceLine__c> bInvLin=[SELECT Id, blng__OrderProduct__c,blng__OrderProduct__r.OrderId ,blng__Invoice__c FROM blng__InvoiceLine__c where blng__Invoice__c =:invoiceid];
        for(blng__InvoiceLine__c invLin: bInvLin){
            orderIds.add(invLin.blng__OrderProduct__r.OrderId);
        }
        
        totalAmount = 0.0;
        orderList = [SELECT Id, AccountId, Account.Name,Animal_Name__c,OrderNumber,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode, OwnerId,Owner.Name,TotalAmount, Pricebook2Id, OriginalOrderId, Type,(SELECT Id, Product2Id, Product2.ProductCode , OrderId, PricebookEntryId, OrderItemNumber,OriginalOrderItemId, AvailableQuantity, Quantity, UnitPrice, ListPrice, TotalPrice, SBQQ__ChargeType__c FROM OrderItems)FROM Order where id IN: orderIds];
        for(Order ordr: orderList){
            totalAmount += ordr.TotalAmount;
        }
        numberOfOrders = orderList.size();
        shippingCost = 12*numberOfOrders;
        discount = 8.70;
        totalAmountWithoutTVA = shippingCost+totalAmount-discount;
        system.debug('totalAmountWithoutTVA'+totalAmountWithoutTVA);
        if(fieldValue == 'Clinic B2B VAT export'){
            TVA = 1;
            totalAmountWithTVA = totalAmountWithoutTVA;
        }
        else{
            TVA = 20;
            TVAAmount = totalAmountWithoutTVA*TVA/100;
            totalAmountWithTVA = totalAmountWithoutTVA-TVAAmount;
        }
        
        
        accountName = orderList[0].Account.Name;
        billingStreet = orderList[0].Account.BillingStreet;
        billingCity = orderList[0].Account.BillingCity;
        billingPostalCode = orderList[0].Account.BillingPostalCode;
        billingCityCode = orderList[0].Account.BillingPostalCode +' '+orderList[0].Account.BillingCity;
        symbol = getCurrencySymbol();
        lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('', '- None -'));
        lstnamesel.add(new selectoption('Clinic B2B','Clinic B2B'));
        lstnamesel.add(new selectoption('Clinic B2B VAT export','Clinic B2B VAT export'));
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
    
}