/**
 * Created by Ingrid on 15-01-24.
 */

 @IsTest 
 private with sharing class CV_CheckBankPaymentOrderBatchPKTest {

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
                Statut_Banque__c = 'En Cours',
                Statut_Banque_CDN__c = 'En Cours',
                Payment_Order_Id__c = 'FACCV-20240118-0003'
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

    }

    @IsTest
    static void testBatchBehavior() {
        CV_BankPaymentOrderService.bypassToken =true;
        blng__InvoiceLine__c invoiceLine = [SELECT Id, blng__Invoice__c,blng__Subtotal__c, blng__Product__c, blng__OrderProduct__c FROM blng__InvoiceLine__c];
        System.debug('***IMA blng__InvoiceLine__c check == ' + invoiceLine);
        invoiceLine.blng__Subtotal__c = 100;
        update invoiceLine;

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'PAYTWEAKCHECK';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_CheckBankPaymentOrderBatchPAYTWEAK batch = new CV_CheckBankPaymentOrderBatchPAYTWEAK();
        Database.executeBatch(batch);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
        ]);
        blng__Invoice__c invoice = [SELECT Id, blng__PaymentStatus__c,blng__Balance__c, Payment_Order_Id__c, Message_d_erreur__c,Statut_Banque__c FROM blng__Invoice__c];
        System.debug('***IMA invoice check == ' + invoice);
        System.debug('***IMA blng__InvoiceLine__c check == ' + invoiceLine);

        System.assertEquals(1, interfaceMonitorings.size());

        //blng__Invoice__c invoice = [SELECT Id, blng__PaymentStatus__c, Payment_Order_Id__c, Message_d_erreur__c,Statut_Banque__c FROM blng__Invoice__c];
        System.assertEquals('FACCV-20240118-0003', invoice.Payment_Order_Id__c);
        System.assertEquals('Payé', invoice.Statut_Banque__c);

    }

    @IsTest
    static void testSchedule() {
        CV_BankPaymentOrderService.bypassToken =true;

        System.Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'PAYTWEAK';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        String sch2 = '0 5 * * * ?';

        String jobId = CV_CheckBankPaymentOrderBatchPAYTWEAK.scheduleThis(sch2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }
}