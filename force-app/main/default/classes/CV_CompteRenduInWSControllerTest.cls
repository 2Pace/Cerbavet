/**
 * Created by Michael on 11-07-22.
 * Updated by Thibaut BENTZ on 20-07-23
 */

@IsTest
private class CV_CompteRenduInWSControllerTest {

    /** Data Setup **/
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
        orderNew.IDDossier__c = '12345678';
        orderNew.Numero__c = 'C123456789';
        insert orderNew;
                
        SBQQ.TriggerControl.disable();
        
        // If you still need this part, un-comment it
        blng__GLRule__c taxGLRule = new blng__GLRule__c();
        taxGLRule.name = 'Regle de facturation GL';
        taxGLRule.blng__Active__c = true;
        insert taxGLRule;
    
        OrderItem item = new OrderItem();
        item.OrderId = orderNew.Id;
        item.Product2Id = normalProduct.Id;
        item.UnitPrice = 240;
        item.blng__BillableUnitPrice__c = 240;
        item.Quantity = 24;
        item.PricebookEntryId = CV_DataFactory.pricebookEntriesStatic[0].id;
        item.blng__TaxRule__c = CV_DataFactory.taxRuleStatic.id;
        item.blng__TaxGLRule__c  = taxGLRule.id;  // if you still need this part
        item.SBQQ__Activated__c  = false;
        item.blng__BillingRule__c = CV_DataFactory.billRuleStatic.Id;
        
        insert item;
        
        orderNew.Status = 'Activated';
        update orderNew;
    
        SBQQ.TriggerControl.enable();
    }
/*
    @IsTest
    static void testBehavior() {

        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = 'C123456789';
        compteRenduECVRequest.correspondantId = CV_DataFactory.biSpeStatic.Code_compte_metier__c;

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(compteRenduECVRequest));
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();

        CV_CompteRenduInWSController.processCompteRenduFromECV();

        Test.stopTest();

        String testBlob = res.responseBody.toString();

        System.debug('======================== Response Body: ' + testBlob);
        CV_CompteRenduInWSController.CompteRenduECVResponse compteRenduECVResponse = (CV_CompteRenduInWSController.CompteRenduECVResponse)JSON.deserialize(testBlob, CV_CompteRenduInWSController.CompteRenduECVResponse.class);
        System.assertEquals('UNBLOCK', compteRenduECVResponse.reportStatus);

    }
/*
    @IsTest
    static void testBehaviorProprioNoInvoice() {

        Order order = [SELECT Id, Conditions_de_Reglement_Cerbavet__c FROM Order];
        order.Conditions_de_Reglement_Cerbavet__c = 'Non Régleur';
        update order;

        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = '12345678';
        compteRenduECVRequest.correspondantId = '12345';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(compteRenduECVRequest));
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();

        CV_CompteRenduInWSController.processCompteRenduFromECV();

        Test.stopTest();

        String testBlob = res.responseBody.toString();
        CV_CompteRenduInWSController.CompteRenduECVResponse compteRenduECVResponse = (CV_CompteRenduInWSController.CompteRenduECVResponse)JSON.deserialize(testBlob, CV_CompteRenduInWSController.CompteRenduECVResponse.class);
        System.assertEquals('BLOCK', compteRenduECVResponse.reportStatus);

    }

    @IsTest
    static void testBehaviorProprio() {

        Order order = [SELECT Id, Conditions_de_Reglement_Cerbavet__c FROM Order];
        order.Conditions_de_Reglement_Cerbavet__c = 'Non Régleur';
        update order;

        OrderItem orderItem = [SELECT Id, Product2Id FROM OrderItem];
        Account account = [SELECT Id FROM Account];

        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = '12345678';
        compteRenduECVRequest.correspondantId = '12345';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(compteRenduECVRequest));
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;


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
                blng__Order__c = order.Id
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

        CV_CompteRenduInWSController.processCompteRenduFromECV();

        Test.stopTest();

        String testBlob = res.responseBody.toString();
        CV_CompteRenduInWSController.CompteRenduECVResponse compteRenduECVResponse = (CV_CompteRenduInWSController.CompteRenduECVResponse)JSON.deserialize(testBlob, CV_CompteRenduInWSController.CompteRenduECVResponse.class);
        System.assertEquals('BLOCK', compteRenduECVResponse.reportStatus);

        order = [SELECT Id, Statut_Compte_Rendu__c FROM Order];
        System.assertEquals('Oui', order.Statut_Compte_Rendu__c);

    }

    @IsTest
    static void testError1() {

        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = '123456';
        compteRenduECVRequest.correspondantId = '12345';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(compteRenduECVRequest));
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();

        CV_CompteRenduInWSController.processCompteRenduFromECV();

        Test.stopTest();

        String testBlob = res.responseBody.toString();
        System.assertEquals(404, res.statusCode);
        System.assert(testBlob.contains('Dossier non trouvé'));

    }

    @IsTest
    static void testError2() {

        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = '12345678';
        compteRenduECVRequest.correspondantId = '1234556';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(compteRenduECVRequest));
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();

        CV_CompteRenduInWSController.processCompteRenduFromECV();

        Test.stopTest();

        String testBlob = res.responseBody.toString();
        System.assertEquals(409, res.statusCode);
        System.assert(testBlob.contains('Mismatch'));

    }
*/

    static {
//        setupTestData();
    }
/*
private static void setupTestData() {
    testAccount = new Account(Name='Test Account');
    insert testAccount;

    // Instantiate the Pricebook2 record first, setting the Id
    Pricebook2 standardPricebook2 = new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
    );

    // Run an update DML on the Pricebook2 record
    // This is the weird workaround that enables IsStandard to become true
    // on the PricebookEntry record
    update standardPricebook2;

    // Create a test Product2 and insert it
    Product2 testProduct = new Product2(
        Name = 'Test Product',
        ProductCode = 'FDD8',
        SBQQ__ChargeType__c = 'Usage'
    );
    insert testProduct;

    // Create a test PricebookEntry and insert it
    PricebookEntry testPricebookEntry = new PricebookEntry(
        Pricebook2Id = standardPricebook2.Id,
        Product2Id = testProduct.Id,
        UnitPrice = 10
    );
    insert testPricebookEntry;

    testOrder = new Order(
        AccountId = testAccount.Id,
        Numero__c = 'TEST123',
        Conditions_de_Reglement_Cerbavet__c = 'Régleur',
        EffectiveDate = Date.today(),
        Status = 'Draft',
        Pricebook2Id = Test.getStandardPricebookId(),
        blng__BillingDayOfMonth__c = '1',
        SBQQ__PaymentTerm__c = 'Net 30',
        IDDossier__c = '12345678'
    );
    insert testOrder;

    testInvoice = new blng__Invoice__c(
        blng__InvoiceStatus__c = 'Posted',
        Payment_Order_Id_CDN__c = testOrder.Id,
        Statut_Banque__c = 'Payé',
        blng__Account__c = testAccount.Id
    );
    insert testInvoice;
    
    // Create billing rule
    blng__BillingRule__c billingRule = new blng__BillingRule__c(
        Name = 'Nom de la règle de facturation',
        blng__GenerateInvoices__c = 'Yes',
        blng__InitialBillingTrigger__c = 'Order Product Activation Date',
        CurrencyIsoCode = 'EUR',
        blng__Active__c = true,
        blng__AmendmentBillCycleDateAlignment__c = 'Do not align amended Order Product',
        blng__PartialPeriodTreatment__c = 'Separate',
        blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day of Month'
    );
    insert billingRule;
    
    // Create an OrderItem and associate it with the Order
    OrderItem orderItem = new OrderItem(
        OrderId = testOrder.Id,
        Product2Id = testProduct.Id,
        Quantity = 1,
        UnitPrice = 100,
        PricebookEntryId = testPricebookEntry.Id,
	    blng__BillingRule__c = billingRule.Id
    );
    insert orderItem;
}*/
    
    /** Error handling tests **/
    @isTest static void testMissingParameters() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1/ecvreport/';
        req.httpMethod = 'POST';
    
        RestContext.request = req;
        RestContext.response = res;
    
        CV_CompteRenduInWSController.processCompteRenduFromECV();
    
        System.assertEquals(400, res.statusCode);
    }
    
    @isTest static void testMismatchedCorrespondantID() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/v1/ecvreport/';
        req.httpMethod = 'POST';
    
        req.params.put('recordNumber', 'C123456789'); 
        req.params.put('correspondantId', 'wrongCorrespondantId');
    
        RestContext.request = req;
        RestContext.response = res;
    
        CV_CompteRenduInWSController.processCompteRenduFromECV();
    
        System.assertEquals(409, res.statusCode);
    }
    
    @isTest static void testNoMatchingAccount() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/services/apexrest/v1/ecvreport/';
        req.httpMethod = 'POST';
    
        req.params.put('recordNumber', '123'); 
        req.params.put('correspondantId', '12345');
    
        RestContext.request = req;
        RestContext.response = res;
    
        CV_CompteRenduInWSController.processCompteRenduFromECV();
    
        System.assertEquals(404, res.statusCode);
    }
    
    @IsTest
    static void testOrderAndOrderInvoiceNotFound() {
        // Create a test REST request with the request parameters
        RestRequest req = new RestRequest();
        req.params.put('recordNumber', 'NonExistingRecordNumber');
        req.params.put('correspondantId', '12345');
        req.httpMethod = 'POST';
        RestContext.request = req;
    
        // Create a test REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
    
        // Execute the controller method
        Test.startTest();
        CV_CompteRenduInWSController.processCompteRenduFromECV();
        Test.stopTest();
    
        // Verify the response status code is 404 (Not Found)
        System.assertEquals(404, res.statusCode);
    }


    /** Sucess Status tests **/
    @IsTest
    static void testHttpCode200AndPaidStatus() {
    
        // Create a test request with the record number and correspondantId
        CV_CompteRenduInWSController.CompteRenduECVRequest compteRenduECVRequest = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        compteRenduECVRequest.recordNumber = 'C123456789';
        compteRenduECVRequest.correspondantId = '12345';
    
        // Create a test REST request
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
    
        // Set the request parameters
        req.params.put('recordNumber', 'C123456789');
        req.params.put('correspondantId', '12345');
    
        RestContext.request = req;
    
        // Create a test REST response
        RestResponse res = new RestResponse();
        RestContext.response = res;
    
        // Execute the controller method
        Test.startTest();
        CV_CompteRenduInWSController.processCompteRenduFromECV();
        Test.stopTest();
    
        // Verify the response status code is 200 (OK)
        System.assertEquals(200, res.statusCode);
    
        // Verify the reportStatus is "UNBLOCK"
        CV_CompteRenduInWSController.CompteRenduECVResponse response = (CV_CompteRenduInWSController.CompteRenduECVResponse) JSON.deserialize(res.responseBody.toString(), CV_CompteRenduInWSController.CompteRenduECVResponse.class);
        System.assertEquals('UNBLOCK', response.reportStatus);
    }


    /** Models tests **/
    @isTest static void testCompteRenduECVResponseInitialization() {
        // Arrange & Act
        CV_CompteRenduInWSController.CompteRenduECVResponse response = new CV_CompteRenduInWSController.CompteRenduECVResponse();
        response.paymentStatus = 'Paid';
        response.reportStatus = 'block';

        // Assert
        System.assertEquals('Paid', response.paymentStatus, 'Payment status should be set correctly');
        System.assertEquals('block', response.reportStatus, 'Report status should be set correctly');
    }

    @isTest static void testCompteRenduECVRequestInitialization() {
        // Arrange & Act
        CV_CompteRenduInWSController.CompteRenduECVRequest request = new CV_CompteRenduInWSController.CompteRenduECVRequest();
        request.recordNumber = '123456';
        request.correspondantId = '987654';

        // Assert
        System.assertEquals('123456', request.recordNumber, 'Record number should be set correctly');
        System.assertEquals('987654', request.correspondantId, 'Correspondant Id should be set correctly');
    }
    
    
    /** Static final string tests **/
    @isTest static void testStaticStringGetters() {
        System.assertEquals('Non Régleur', CV_CompteRenduInWSController.getNON_PAYER(), 'NON_PAYER getter returned incorrect value');
        System.assertEquals('PAID', CV_CompteRenduInWSController.getPAYMENT_STATUS_PAID(), 'PAYMENT_STATUS_PAID getter returned incorrect value');
        System.assertEquals('UNPAID', CV_CompteRenduInWSController.getPAYMENT_STATUS_UNPAID(), 'PAYMENT_STATUS_UNPAID getter returned incorrect value');
        System.assertEquals('BLOCK', CV_CompteRenduInWSController.getREPORT_STATUS_BLOCK(), 'REPORT_STATUS_BLOCK getter returned incorrect value');
        System.assertEquals('UNBLOCK', CV_CompteRenduInWSController.getREPORT_STATUS_UNBLOCK(), 'REPORT_STATUS_UNBLOCK getter returned incorrect value');
        System.assertEquals('Payé', CV_CompteRenduInWSController.getBANQUE_PAID(), 'BANQUE_PAID getter returned incorrect value');
        System.assertEquals('En Cours', CV_CompteRenduInWSController.getBANQUE_RUNNING(), 'BANQUE_RUNNING getter returned incorrect value');
    }
}