/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_BankPaymentOrderServiceTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

        SBQQ.TriggerControl.disable();

        Order orderNew = new Order(
                AccountId = account.Id,
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebook2.Id,
                Status = 'Draft',
                blng__BillingDayOfMonth__c = '1',
                SBQQ__PaymentTerm__c = 'Net 30',
                blng__InvoiceBatch__c = 'Cerbavet Analysis'
        );
        insert orderNew;

        OrderItem orderItem = new OrderItem(
                OrderId = orderNew.Id,
                Product2Id = normalProduct.Id,
                UnitPrice = 240,
                Quantity = 24,
                PricebookEntryId=pricebookEntries[0].id
        );

        insert orderItem;


        orderNew.Status = 'Activated';
        update orderNew;

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Statut_Integration_ECV__c = 'A Envoyer',
                Numero_Facturation_Cerbavet__c ='FACCV-20240118-0003',
                Statut_Banque_CDN__c = 'En Cours'
        );
        insert testInvoice;

        SBQQ.TriggerControl.enable();   

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

    }

    @IsTest
    static void testGeneratePayment() {

        String query = CV_BankPaymentOrderService.getSelectionQuery(false, false);

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'CDN';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_BankPaymentOrderService.generatePaymentOrderIds(invoices, false);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
        ]);
        //System.assertEquals(1, interfaceMonitorings.size());

        blng__Invoice__c invoice = [SELECT Id, blng__PaymentStatus__c,Payment_Order_Id_CDN__c, Message_d_erreur__c, Statut_Banque_CDN__c FROM blng__Invoice__c  WHERE Payment_Order_Id_CDN__c = 'dflsmfsfm-dfjfosf-12324'  LIMIT 1];
        System.assertEquals('dflsmfsfm-dfjfosf-12324', invoice.Payment_Order_Id_CDN__c);
        System.assertEquals('En Cours', invoice.Statut_Banque_CDN__c);

    }

    @IsTest
    static void testGeneratePaymentPaytweak() {

        System.debug('**** IMA testGeneratePaymentPaytweak class');

        String query = CV_BankPaymentOrderService.getSelectionQuery(false, true);

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'PAYTWEAK';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_BankPaymentOrderService.generatePaymentOrderIds(invoices, true);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
        ]);
        //System.assertEquals(1, interfaceMonitorings.size());

        blng__Invoice__c invoice = [SELECT Id, blng__PaymentStatus__c, Payment_Order_Id__c,blng__TotalAmount__c, Message_d_erreur__c, Statut_Banque__c FROM blng__Invoice__c WHERE Payment_Order_Id__c != '' LIMIT 1];
        System.debug('**** IMA blng__TotalAmount__c value == ' + invoice.blng__TotalAmount__c);
        System.assertEquals('FACCV-20240118-0003', invoice.Payment_Order_Id__c);
        System.assertEquals('En Cours', invoice.Statut_Banque__c);

    }

    @IsTest
    static void testCheckPayments() {

        blng__Invoice__c invoice = [SELECT Id, Payment_Order_Id_CDN__c FROM blng__Invoice__c WHERE  Statut_Banque_CDN__c = 'En Cours' LIMIT 1];
        invoice.Payment_Order_Id_CDN__c = 'dflsmfsfm-dfjfosf-12324';
        update invoice;

        String query = CV_BankPaymentOrderService.getSelectionQuery(true, false);

        List<blng__Invoice__c> invoices = (List<blng__Invoice__c>)Database.query(query);

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'CDNCHECK';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_BankPaymentOrderService.checkPaymentOrders(invoices, false);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
        ]);
        System.assertEquals(1, interfaceMonitorings.size());

        invoice = [SELECT Id, blng__PaymentStatus__c, Payment_Order_Id__c,Payment_Order_Id_CDN__c, Message_d_erreur__c, Statut_Banque_CDN__c FROM blng__Invoice__c WHERE Payment_Order_Id_CDN__c = 'dflsmfsfm-dfjfosf-12324'  LIMIT 1];
        System.assertEquals('dflsmfsfm-dfjfosf-12324', invoice.Payment_Order_Id_CDN__c);
        System.assertEquals('Payé', invoice.Statut_Banque_CDN__c);

    }

    @IsTest
    static void testCheckPayment() {

        blng__Invoice__c invoice = [SELECT Id,Payment_Order_Id_CDN__c, blng__PaymentStatus__c FROM blng__Invoice__c WHERE  Statut_Banque_CDN__c = 'En Cours' LIMIT 1];
        invoice.Payment_Order_Id_CDN__c = 'dflsmfsfm-dfjfosf-12324';
        update invoice;

        System.debug('========================= TEST TEST TEST invoice: ' + invoice);


        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'CDNCHECK';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_BankPaymentOrderService.checkPaymentForECVCall(invoice.Id);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
        ]);
        System.assertEquals(1, interfaceMonitorings.size());

        invoice = [SELECT Id, blng__PaymentStatus__c, Payment_Order_Id_CDN__c, Message_d_erreur__c, Statut_Banque_CDN__c FROM blng__Invoice__c WHERE Payment_Order_Id_CDN__c = 'dflsmfsfm-dfjfosf-12324' LIMIT 1];
        System.assertEquals('dflsmfsfm-dfjfosf-12324', invoice.Payment_Order_Id_CDN__c );
        System.assertEquals('Payé', invoice.Statut_Banque_CDN__c);

    }

}