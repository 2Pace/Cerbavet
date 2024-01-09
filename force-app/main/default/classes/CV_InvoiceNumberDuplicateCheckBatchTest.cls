/**
 * Created by Michael on 16-10-22.
 */

@IsTest
private class CV_InvoiceNumberDuplicateCheckBatchTest {


    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{normalProduct}, pricebook2);

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

        SBQQ.TriggerControl.disable();

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
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id
        );
        insert testInvoice;

        blng__InvoiceLine__c testInvoiceLine = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine;

        blng__Invoice__c testInvoice2 = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id
        );
        insert testInvoice2;

        blng__InvoiceLine__c testInvoiceLine2 = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine2;

        SBQQ.TriggerControl.enable();

    }


    @IsTest
    static void testBatchBehavior() {

        SBQQ.TriggerControl.disable();

        List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>([SELECT Id, Numero_Facturation_Cerbavet__c FROM blng__Invoice__c]);

        for (blng__Invoice__c invoice : invoicesToUpdate) {
            invoice.Numero_Facturation_Cerbavet__c = '1';
        }

        update invoicesToUpdate;

        Test.startTest();

        CV_InvoiceNumberDuplicateCheckBatch batch = new CV_InvoiceNumberDuplicateCheckBatch(null);
        Database.executeBatch(batch);

        Test.stopTest();

        invoicesToUpdate = new List<blng__Invoice__c>([SELECT Id, Numero_Facturation_Cerbavet__c FROM blng__Invoice__c]);
        System.debug('============================== TEST TEST TEST invoicesToUpdate: ' + invoicesToUpdate);

        System.assertNotEquals(invoicesToUpdate[0].Numero_Facturation_Cerbavet__c, invoicesToUpdate[1].Numero_Facturation_Cerbavet__c);

    }

    @IsTest
    static void testSchedule() {

        System.Test.startTest();

        String sch2 = '0 5 * * * ?';
        String jobId = CV_InvoiceNumberDuplicateCheckBatch.scheduleThis(sch2);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

        System.assertEquals('0 5 * * * ?', ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        System.Test.stopTest();

    }
}