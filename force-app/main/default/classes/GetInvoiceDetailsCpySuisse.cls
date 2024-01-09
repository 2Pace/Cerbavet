public class GetInvoiceDetailsCpySuisse{
    //Apex properties or variables
    ApexPages.StandardController sc;
    public List<Order>  orderList {get; set;}
    public List<OrderItem> ordrItm {get; set;}
    public String accountName { get; set; }
    public Boolean billingAccount { get; set; }
    public String patientName { get; set; }
    public Date startDate { get; set; }
    public String parentAccount { get; set; }
    public String petCode { get; set; }
    public String petName { get; set; }
    public String dossier {get; set;}
    public String patientAddress { get; set; }
    public String patientCity { get; set; }
    public String patientPostalCode { get; set; }
    public String notes { get; set; }
    public String orderName { get; set; }
    public String codeCorresponding {get; set;}
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
    public Decimal shippingCost { get; set; }
    public Integer TVA { get; set; }
    public Case cas { get; set; }
    Public string selectedname{get;set;}
    Public string renderType{get;set;}
    Public string symbol{get;set;}
    Public string conName{get;set;}
    Public string billingCityCode{get;set;}
    Public string templateName{get;set;}
    Public string invoicePaymentStatus{get;set;}
    Public string txCountry{get;set;}
    Public List<Selectoption> lstnamesel {get; set;}
    //public List<SBQQ__QuoteLine__c> sbQuoteLine {get;set;}
    public List<SBQQ__QuoteLine__c> sbQuoteLineList {get;set;}
    public SBQQ__QuoteLine__c sbQLine {get;set;}
    public SBQQ__QuoteLine__c sbQLineLast {get;set;}
    public list<wrapper> wrp {get;set;}
    public map<string,list<wrapper>> mapAccToOrder{get;set;}
    public map<string,Decimal> mapAccToOrderAmount{get;set;}
    public list<mainWrapper> wrpMain {get;set;}
    
    public List<blng__InvoiceLine__c> InvoiceLineItem{get;set;}
    
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
    public GetInvoiceDetailsCpySuisse(ApexPages.StandardController sc) {
        testMethods();
    }
    public void testMethods(){
        string invoiceid=ApexPages.currentPage().getParameters().get('id');
        string accountId = '';
        system.debug('selectedname'+fieldValue);
        String orderProd = '';
        List<String> qLIds = new List<String>();
        List<String> orderIds = new List<String>();
        List<String> quoteIds = new List<String>();
        map<Id,blng__InvoiceLine__c> qLidToIL = new map<Id,blng__InvoiceLine__c>();
        wrp=new list<wrapper>();
        wrpMain = new list<mainWrapper>();
        totalAmount = 0;
        mapAccToOrder = new map<string,list<wrapper>>();
        mapAccToOrderAmount = new map<string,Decimal>();
        List<blng__InvoiceLine__c> bInvLin = [SELECT Id, blng__Product__r.Name,blng__Quantity__c,blng__Subtotal__c, blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.SBQQ__QuoteLine__c,blng__Invoice__c,blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Notes__c,blng__Product__r.Family,blng__Invoice__r.blng__PaymentStatus__c   FROM blng__InvoiceLine__c where blng__Invoice__c =:invoiceid];
        if(bInvLin.size()>0){
            invoicePaymentStatus = bInvLin[0].blng__Invoice__r.blng__PaymentStatus__c;
            List<Order> IB= [SELECT Id, blng__InvoiceBatch__c FROM Order where id =: bInvLin[0].blng__OrderProduct__r.OrderId];
            templateName = IB[0].blng__InvoiceBatch__c;
            if(templateName == 'Cerbavet College'){
                for(blng__InvoiceLine__c invLin: bInvLin){
                    system.debug('==QL>'+invLin.blng__OrderProduct__r.SBQQ__QuoteLine__c);
                    totalAmount +=invLin.blng__Subtotal__c; 
                    notes = invLin.blng__Invoice__r.blng__Notes__c;
                    system.debug('first');
                    List<SBQQ__QuoteLine__c> sbQuoteLine = new List<SBQQ__QuoteLine__c>();
                    if(invLin.blng__OrderProduct__r.SBQQ__QuoteLine__c != null){
                        sbQuoteLine = [SELECT Id, SBQQ__Number__c, SBQQ__Quote__c, Date_Session__c ,SBQQ__NetPrice__c,SBQQ__Quantity__c , SBQQ__NetTotal__c, SBQQ__Product__c, SBQQ__ProductName__c, SBQQ__Product__r.Description, SBQQ__RequiredBy__c FROM SBQQ__QuoteLine__c where SBQQ__RequiredBy__c =:invLin.blng__OrderProduct__r.SBQQ__QuoteLine__c order by SBQQ__Number__c];
                    }
                    wrapper wrpr = new wrapper();
                    wrpr.Inline = invLin;
                    wrpr.Qtline = sbQuoteLine; 
                    wrp.add(wrpr);
                    orderProd=invLin.blng__OrderProduct__r.OrderId;
                }
                List<OrderItem> oItm= [SELECT OrderId,Order.OrderNumber, Id, Product2Id, blng__TaxCountry__c FROM OrderItem where OrderId =:orderProd];
                system.debug('oItm==>'+oItm);
                orderName = oItm[0].Order.OrderNumber;
                
                TVA = 20;
                totalAmountWithTVA = totalAmount*TVA/100;
                TVAAmount = totalAmount + totalAmountWithTVA;
            }
            else if(templateName == 'Cerbavet Analysis Suisse'){
                system.debug('Cerbavet Analysis Suisse');
                shippingCost = 0.0;
                discount = 0.0;
                totalAmount = 0.0;
                TVAAmount = 0.0;
                for(blng__InvoiceLine__c invLin: bInvLin){
                    if(invLin.blng__Product__r.Family == 'Cerbavet Transport'){shippingCost += invLin.blng__Subtotal__c;}
                    orderIds.add(invLin.blng__OrderProduct__r.OrderId);
                }
                List<String> Accounts = new List<String>();
                String accName;
                orderList = [SELECT Id, AccountId,blng__BillingAccount__c,Nom_Patient__c,IDDossier__c, Account.Name,Animal_Name__c,OrderNumber,SBQQ__TaxAmount__c,Account.BillingStreet,Account.BillingCity,Account.BillingPostalCode, OwnerId,Owner.Name,TotalAmount, Pricebook2Id, OriginalOrderId, Type,(SELECT Id, Product2Id, Product2.ProductCode ,Product2.Family, OrderId, PricebookEntryId, OrderItemNumber,OriginalOrderItemId, AvailableQuantity, Quantity, UnitPrice, ListPrice, TotalPrice, SBQQ__ChargeType__c,Remise_commerciale__c,blng__TaxCountry__c  FROM OrderItems where Product2.Family != 'Cerbavet Transport')FROM Order where id IN: orderIds];
                for(Order ordr: orderList){
                    
                    if(ordr.blng__BillingAccount__c == null){
                        Decimal totalOLIAmount = 0.0;
                        accountId = ordr.AccountId;
                        TVAAmount += ordr.SBQQ__TaxAmount__c;
                        for(OrderItem Oi: ordr.OrderItems){
                            totalAmount += Oi.TotalPrice;
                            totalOLIAmount += Oi.TotalPrice;
                            discount += Oi.Remise_commerciale__c;
                            txCountry =  Oi.blng__TaxCountry__c;
                        }
                        wrapper wrpr = new wrapper();
                        wrpr.Orders = ordr;
                        wrpr.OLIAmount = totalOLIAmount; 
                        
                        wrp.add(wrpr);
                    }
                    else{
                        system.debug('Cerbavet Analysis Else');
                        List<wrapper> newWrp = new List<wrapper>();
                        Decimal totalOLIAmount = 0.0;
                        accountId = ordr.AccountId;
                        billingAccount = TRUE;
                        TVAAmount += ordr.SBQQ__TaxAmount__c;
                        for(OrderItem Oi: ordr.OrderItems){
                            totalAmount += Oi.TotalPrice;
                            totalOLIAmount += Oi.TotalPrice;
                            discount += Oi.Remise_commerciale__c;
                            txCountry =  Oi.blng__TaxCountry__c;
                        }
                        wrapper wrpr = new wrapper();
                        wrpr.Orders = ordr;
                        wrpr.OLIAmount = totalOLIAmount; 
                        newWrp.add(wrpr);
                        string ac = ordr.Account.Name;
                        system.debug('ordr.Account.Name'+ordr.Account.Name);
                        //system.debug('mapAccToOrder>>>>'+mapAccToOrder.keySet());
                       // system.debug('mapAccToOrder.containsKey(ordr.Account.Name)'+mapAccToOrder.containsKey(ac));
                        if(ordr.Account.Name != null){
                            if(mapAccToOrder.containsKey(ordr.Account.Name)){
                                List<wrapper> wrprs = mapAccToOrder.get(ordr.Account.Name);
                                wrprs.addAll(newWrp);
                                mapAccToOrder.put(ordr.Account.Name, wrprs);
                            }
                            else{
                                mapAccToOrder.put(ordr.Account.Name,newWrp);
                            }
                            
                            if(mapAccToOrderAmount.containsKey(ordr.Account.Name)){
                                decimal amt= mapAccToOrderAmount.get(ordr.Account.Name);
                                amt += ordr.TotalAmount;
                                mapAccToOrderAmount.put(ordr.Account.Name, amt);
                            }
                            else{
                                mapAccToOrderAmount.put(ordr.Account.Name, ordr.TotalAmount);
                            }
                        }
                    }
                    
                }
                
                numberOfOrders = orderList.size();
                
                totalAmountWithoutTVA = shippingCost+totalAmount-discount;
                system.debug('totalAmountWithoutTVA'+totalAmountWithoutTVA);
                totalAmountWithTVA = totalAmountWithoutTVA+TVAAmount;
                system.debug('mapAccToOrder>>>>'+mapAccToOrder);
            }
            else if(templateName == 'Cerbavet Analysis Proprio Suisse'){
                system.debug('Cerbavet Analysis Proprio Suisse');
                shippingCost = 0.0;
                discount = 0.0;
                totalAmount = 0.0;
                TVAAmount = 0.0;
                InvoiceLineItem = bInvLin;
                for(blng__InvoiceLine__c invLin: bInvLin){
                    orderIds.add(invLin.blng__OrderProduct__r.OrderId);
                    totalAmount += invLin.blng__Subtotal__c;
                }
                
                orderList = [SELECT Id, Adresse_Patient__c,IDDossier__c, Animal_Name__c,Prenom_Patient__c,Code_Civilite__c, EffectiveDate,Nom_Patient__c,Ville_Patient__c,Code_Postal_Patient__c, OrderNumber,SBQQ__TaxAmount__c, OwnerId, Owner.Name, TotalAmount, Pricebook2Id, OriginalOrderId, Type FROM Order where id IN: orderIds];
                if(orderList.size() > 0){
                    dossier = orderList[0].IDDossier__c;
                    for(Order ordr: orderList){
                    TVAAmount += ordr.SBQQ__TaxAmount__c;
                    for(OrderItem Oi: ordr.OrderItems){
                        discount += Oi.Remise_commerciale__c;
                    }
                }
                }
                
                patientName = orderList[0].Nom_Patient__c;
                if(orderList[0].Adresse_Patient__c != null){patientAddress = orderList[0].Adresse_Patient__c; }
                if(orderList[0].Ville_Patient__c != null){patientCity = orderList[0].Ville_Patient__c; }
                if(orderList[0].Code_Postal_Patient__c != null){patientPostalCode = orderList[0].Code_Postal_Patient__c; }
                patientPostalCode +=' '+patientCity;
                startDate = orderList[0].EffectiveDate;
                
                petCode = orderList[0].Code_Civilite__c;
                petName = orderList[0].Prenom_Patient__c;
                
                totalAmountWithoutTVA = shippingCost+totalAmount-discount;
                totalAmountWithTVA = totalAmountWithoutTVA+TVAAmount;
            }
            
        }
        
        system.debug('wrpr===>'+wrp);
        
        
        List<blng__Invoice__c> blngInvoice= [SELECT Id, Name, blng__Account__r.Name, blng__Account__r.BillingStreet,
                                             blng__Account__r.BillingPostalCode, blng__Account__r.BillingCity,blng__Account__r.Code_compte_metier__c
                                             ,Numero_Facture_Cerba__c FROM blng__Invoice__c where id =: invoiceid];
        List<Account> acc = [Select id,parent.Name from Account where id=:blngInvoice[0].blng__Account__c];
        parentAccount = acc[0].parent.Name;
        accountName = '';
        billingStreet='';
        billingPostalCode = '';
        billingCity='';
        if(blngInvoice[0].blng__Account__r.Name != null){accountName = blngInvoice[0].blng__Account__r.Name;}
        if(blngInvoice[0].blng__Account__r.BillingStreet != null){billingStreet = blngInvoice[0].blng__Account__r.BillingStreet;}
        if(blngInvoice[0].blng__Account__r.BillingPostalCode != null){billingPostalCode = blngInvoice[0].blng__Account__r.BillingPostalCode;}
        if(blngInvoice[0].blng__Account__r.BillingCity != null){billingCity = blngInvoice[0].blng__Account__r.BillingCity;}
        billingCityCode = billingPostalCode +' '+billingCity;
        invoiceNumber = blngInvoice[0].Numero_Facture_Cerba__c;
        codeCorresponding =  blngInvoice[0].blng__Account__r.Code_compte_metier__c;
        
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
    public class mainWrapper{
        public String AccountName{get;set;}
        public wrapper wrapList {get;set;}
    }
    public class wrapper{
        public blng__InvoiceLine__c Inline{get;set;}
        public Decimal OLIAmount{get;set;}
        public List<SBQQ__QuoteLine__c> Qtline{get;set;}
        public Order Orders{get;set;}
        public String AccountName{get;set;}
    }
}