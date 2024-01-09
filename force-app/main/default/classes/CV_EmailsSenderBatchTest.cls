/**
 * Created by Michael on 11-07-22.
 */

@IsTest
private class CV_EmailsSenderBatchTest {

    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

        Order orderNew = new Order();
        orderNew.AccountId = account.Id;
        orderNew.EffectiveDate = system.today();
        orderNew.Pricebook2Id = pricebook2.Id;
        orderNew.Status = 'Draft';
        orderNew.blng__BillingDayOfMonth__c = '1';
        orderNew.SBQQ__PaymentTerm__c = 'Net 30';
        insert orderNew;

        OrderItem item = new OrderItem();
        item.OrderId = orderNew.Id;
        item.Product2Id = normalProduct.Id;
        item.UnitPrice = 240;
        item.Quantity = 24;
        item.PricebookEntryId=pricebookEntries[0].id;

        insert item;

        SBQQ.TriggerControl.disable();

        orderNew.Status = 'Activated';
        update orderNew;

        SBQQ.TriggerControl.enable();

        OrderItem orderItem = [SELECT id,Product2Id FROM OrderItem LIMIT 1];

        blng__InvoiceRun__c invoiceRun = new blng__InvoiceRun__c(
                Name = 'Cerbavet Proprio',
                blng__TargetDate__c = Date.today()
        );
        insert invoiceRun;

        blng__Invoice__c testInvoice = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Document_genere__c = true,
                blng__Order__c = orderNew.Id
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

        List<blng__Invoice__c> invoices = CV_PDFManagementService.generatePDFDocuments(new List<blng__Invoice__c>{testInvoice});

    }

    @IsTest
    static void testBatchBehaviorError() {

        Test.startTest();

        CV_EmailsSenderBatch batch = new CV_EmailsSenderBatch(false);
        Database.executeBatch(batch);

        Test.stopTest();

        blng__Invoice__c invoice = [SELECT Id, Message_d_erreur__c FROM blng__Invoice__c];
        System.assertEquals('Pas d\'email patient spécifié', invoice.Message_d_erreur__c);

    }

    @IsTest
    static void testBatchBehavior() {

        SBQQ.TriggerControl.Disable();
        Order order = [SELECT Id, Email_Patient__c FROM Order];
        order.Email_Patient__c = 'test@test.com';
        update order;
        SBQQ.TriggerControl.Enable();

        Test.startTest();

        CV_EmailsSenderBatch batch = new CV_EmailsSenderBatch(false);
        Database.executeBatch(batch);

        Test.stopTest();

        blng__Invoice__c invoice = [SELECT Id, Message_d_erreur__c, Document_envoye__c, Document_Facture_Acquittee_Envoye__c FROM blng__Invoice__c];
        System.debug('==================== TEST TEST invoice: ' + invoice);
        System.assertEquals(true, invoice.Document_envoye__c);

    }


    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';
        String jobId = CV_EmailsSenderBatch.scheduleThis(sch2, false);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        System.Test.stopTest();

    }

}