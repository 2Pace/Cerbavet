/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_InvoiceECVSendingBatchTest {

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
                Statut_Integration_ECV__c = 'A Envoyer'
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
    static void testBatchErrorSending() {

        Test.startTest();
        CV_Intf_WebserviceMock.status = 500;
        CV_Intf_WebserviceMock.interfaceToTest = 'ECV';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_InvoiceECVSendingBatch batch = new CV_InvoiceECVSendingBatch(false);
        Database.executeBatch(batch);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
                WHERE Interface_Name__c= 'ECV'
        ]);
        System.assertEquals(1, interfaceMonitorings.size());
        System.assertEquals('500', interfaceMonitorings[0].Status_Code__c);

    }

    @IsTest
    static void testBatchProprio() {

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'ECV';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        CV_InvoiceECVSendingBatch batch = new CV_InvoiceECVSendingBatch(false);
        Database.executeBatch(batch);

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
                WHERE Interface_Name__c= 'ECV' AND Status_Code__c = '200'
        ]);
        System.assertEquals(1, interfaceMonitorings.size());
    }

//    @IsTest
//    static void testBatchMonthly() {
//
//        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
//                Name = 'Cerbavet Clinic',
//                blng__TargetDate__c = Date.today()
//        );
//        insert invoiceRun;
//
//        blng__Invoice__c invoice = [SELECT Id FROM blng__Invoice__c];
//        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.Id;
//        update invoice;
//
//        Test.startTest();
//        CV_Intf_WebserviceMock.status = 200;
//        CV_Intf_WebserviceMock.interfaceToTest = 'ECV';
//        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());
//
//        CV_InvoiceECVSendingBatch batch = new CV_InvoiceECVSendingBatch(false);
//        Database.executeBatch(batch);
//
//        Test.stopTest();
//
//        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
//                SELECT Id, Interface_Name__c, Status_Code__c
//                FROM Interface_Monitoring__c
//                WHERE Interface_Name__c= 'ECV' AND Status_Code__c = '200'
//        ]);
//
//    }


    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';

        String jobId = CV_InvoiceECVSendingBatch.scheduleThis(sch2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);

        System.assertEquals(0, ct.TimesTriggered);
        System.Test.stopTest();

    }
}