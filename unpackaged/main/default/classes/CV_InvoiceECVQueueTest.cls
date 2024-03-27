/**
 * Created by Michael on 26-08-22.
 */

@IsTest
private class CV_InvoiceECVQueueTest {
    @IsTest
    static void testBehavior() {

        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S';
        conVer.PathOnClient = 'facture.pdf';
        conVer.Title = 'Testing Files';
        conVer.VersionData = Blob.valueOf('some text');
        insert conVer;

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
                Name = 'Cerbavet',
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

        Test.startTest();
        CV_Intf_WebserviceMock.status = 200;
        CV_Intf_WebserviceMock.interfaceToTest = 'ECV';
        Test.setMock(HttpCalloutMock.class, new CV_Intf_WebserviceMock());

        String query = 'SELECT ' + String.join(new List<String>(Schema.getGlobalDescribe().get('blng__Invoice__c').getDescribe().fields.getMap().keySet()), ',') + ' ';
        query += ' ,blng__Order__r.Email_Patient__c, blng__Order__r.Lib_Espece_Patient__c, blng__Account__r.Code_compte_metier__c, blng__Order__r.IDDossier__c';
        query += ',blng__Order__r.Animal_Owner_Name__c,blng__Order__r.Animal_Name__c, blng__Order__r.Prenom_Patient__c';
        query += ' FROM blng__Invoice__c';

        List<blng__Invoice__c> invoices = Database.query(query);

        CV_Intf_Service.loadMDWTransformationsMap('Invoice');
        List<Intf_Sync_Field__mdt> syncFields = CV_Intf_Service.getActiveSyncFields('ECV');

        CV_Intf_InvoiceSchemaBuilder invoiceSchemaBuilder = new CV_Intf_InvoiceSchemaBuilder(invoices[0], conVer, '12345', false);

        System.enqueueJob(new CV_InvoiceECVQueue(new List<CV_Intf_InvoiceSchemaBuilder>{invoiceSchemaBuilder}));

        Test.stopTest();

        List<Interface_Monitoring__c> interfaceMonitorings = new List<Interface_Monitoring__c>([
                SELECT Id, Interface_Name__c, Status_Code__c
                FROM Interface_Monitoring__c
                WHERE Interface_Name__c= 'ECV'
        ]);


    }
}