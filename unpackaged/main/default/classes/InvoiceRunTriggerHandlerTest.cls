/**
 * Created by Michael on 09-11-23.
 */

@IsTest
private class InvoiceRunTriggerHandlerTest {
    @TestSetup
    static void setupData() {

        Pricebook2 pricebook2 = CV_DataFactory.createPriceBook();

        Account account = CV_DataFactory.createCompteSGL(false);
        blng__LegalEntity__c legalEntity = CV_DataFactory.createLegalEntity();

        CV_DataFactory.configureBilling(legalEntity);

        Product2 normalProduct = CV_DataFactory.createProduct('PARSG', false, false, false);

        List<PricebookEntry> pricebookEntries = CV_DataFactory.createPriceBookEntries(new List<Product2>{
                normalProduct
        }, pricebook2);

        SBQQ.TriggerControl.disable();

        Order orderNew = new Order(
                AccountId = account.Id,
                EffectiveDate = Date.today(),
                Pricebook2Id = pricebook2.Id,
                Status = 'Draft',
                blng__BillingDayOfMonth__c = '1',
                SBQQ__PaymentTerm__c = 'Net 30',
                blng__InvoiceBatch__c = 'Cerbavet Analysis',
                IDDossier__c = 'Dossier123456'
        );
        insert orderNew;

        OrderItem orderItem = new OrderItem(
                OrderId = orderNew.Id,
                Product2Id = normalProduct.Id,
                UnitPrice = 240,
                Quantity = 24,
                PricebookEntryId = pricebookEntries[0].id
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


        blng__Invoice__c testInvoice2 = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
        );
        insert testInvoice2;

        blng__InvoiceLine__c testInvoiceLine2 = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice2.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine2;

        blng__Invoice__c testInvoice3 = new blng__Invoice__c(
                blng__Account__c = account.Id,
                blng__InvoiceStatus__c = 'Posted',
                blng__InvoiceRunCreatedBy__c = invoiceRun.Id,
                Statut_Integration_ECV__c = 'A Envoyer'
        );
        insert testInvoice3;

        blng__InvoiceLine__c testInvoiceLine3 = new blng__InvoiceLine__c(
                blng__Invoice__c = testInvoice3.Id,
                blng__OrderProduct__c = orderItem.Id,
                blng__Product__c = orderItem.Product2Id,
                blng__Subtotal__c = 100
        );
        insert testInvoiceLine3;

    }


    @IsTest
    static void testBehavior() {

        blng__InvoiceRun__c invoiceRun = [SELECT Id, blng__Status__c FROM blng__InvoiceRun__c WHERE Name = 'Cerbavet Proprio'];


        Test.startTest();

        invoiceRun.blng__Status__c = 'Completed with errors';
        update invoiceRun;

        List<blng__Invoice__c> invoices = new List<blng__Invoice__c>([
                SELECT Id, Numero_Facturation_Cerbavet__c, blng__Order__c, IDDossier__c
                FROM blng__Invoice__c
                WHERE blng__InvoiceRunCreatedBy__r.Name = 'Cerbavet Proprio'
                ORDER BY Numero_Facturation_Cerbavet__c]);

        System.assertEquals(3, invoices.size());
        System.assert(invoices[0].Numero_Facturation_Cerbavet__c.contains('0001'));
        System.assert(invoices[0].Numero_Facturation_Cerbavet__c.contains('FACCV'));
        System.assert(invoices[1].Numero_Facturation_Cerbavet__c.contains('0002'));
        System.assert(invoices[2].Numero_Facturation_Cerbavet__c.contains('0003'));

        Test.stopTest();

    }
}