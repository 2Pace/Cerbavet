@isTest
private class OcoCorrespondentApiTest {
    
    @isTest
    static void testGetCorrespondentBillingInformations() {
        // Create test data - Pricebooks
        Pricebook2 cerbaVetPricebook = new Pricebook2(Name = 'CerbaVet');
        Pricebook2 domPricebook = new Pricebook2(Name = 'CerbaVet DOM');
        Pricebook2 tomExportPricebook = new Pricebook2(Name = 'CerbaVet TOM et Export');
        insert new List<Pricebook2>{ cerbaVetPricebook, domPricebook, tomExportPricebook };
    
        // Create test data - Legal Entities
        blng__LegalEntity__c swissLegalEntity = new blng__LegalEntity__c(Name = 'Cerbavet Suisse');
        blng__LegalEntity__c franceLegalEntity = new blng__LegalEntity__c(Name = 'Cerbavet France');
        insert new List<blng__LegalEntity__c>{ swissLegalEntity, franceLegalEntity };
    
        // Create test data - Tax Rates
        blng__TaxRate__c franceVAT = new blng__TaxRate__c(blng__Rate__c = 0.2, blng__TaxCode__c = 'TRFM', blng__Priority__c = '1');
        blng__TaxRate__c swissVAT = new blng__TaxRate__c(blng__Rate__c = 0.1, blng__TaxCode__c = 'TRCH', blng__Priority__c = '1');
        blng__TaxRate__c domVAT = new blng__TaxRate__c(blng__Rate__c = 0.15, blng__TaxCode__c = 'TRDOM', blng__Priority__c = '1');
        blng__TaxRate__c exportVAT = new blng__TaxRate__c(blng__Rate__c = 0.25, blng__TaxCode__c = 'TRE', blng__Priority__c = '1');
        insert new List<blng__TaxRate__c>{ franceVAT, swissVAT, domVAT, exportVAT };
    
        // Test case 1: Correspondent from Swiss
        OcoCorrespondentApi.Correspondent swissCorrespondent = new OcoCorrespondentApi.Correspondent();
        swissCorrespondent.Code = 'CH123';
        swissCorrespondent.Name = 'Swiss Correspondent';
        swissCorrespondent = OcoCorrespondentApi.getCorrespondentBillingInformations(swissCorrespondent);
    
        System.assertEquals(cerbaVetPricebook.Id, swissCorrespondent.PricebookId, 'Incorrect PricebookId for Swiss correspondent');
        System.assertEquals(cerbaVetPricebook.Name, swissCorrespondent.PricebookName, 'Incorrect PricebookName for Swiss correspondent');
        System.assertEquals(0.1, swissCorrespondent.VAT, 'Incorrect VAT for Swiss correspondent');
    
        // Test case 2: Correspondent from DOM
        OcoCorrespondentApi.Correspondent domCorrespondent = new OcoCorrespondentApi.Correspondent();
        domCorrespondent.Code = '97123';
        domCorrespondent.Name = 'DOM Correspondent';
        domCorrespondent = OcoCorrespondentApi.getCorrespondentBillingInformations(domCorrespondent);
    
        System.assertEquals(domPricebook.Id, domCorrespondent.PricebookId, 'Incorrect PricebookId for DOM correspondent');
        System.assertEquals(domPricebook.Name, domCorrespondent.PricebookName, 'Incorrect PricebookName for DOM correspondent');
        System.assertEquals(0.15, domCorrespondent.VAT, 'Incorrect VAT for DOM correspondent');
    
        // Test case 3: Correspondent from France
        OcoCorrespondentApi.Correspondent frCorrespondent = new OcoCorrespondentApi.Correspondent();
        frCorrespondent.Code = 'FR123';
        frCorrespondent.Name = 'France Correspondent';
        frCorrespondent.BillingCountryCode = 'FR';
        frCorrespondent.BillingCountry = 'France';
        frCorrespondent = OcoCorrespondentApi.getCorrespondentBillingInformations(frCorrespondent);
    
        System.assertEquals(cerbaVetPricebook.Id, frCorrespondent.PricebookId, 'Incorrect PricebookId for France correspondent');
        System.assertEquals(cerbaVetPricebook.Name, frCorrespondent.PricebookName, 'Incorrect PricebookName for France correspondent');
        System.assertEquals(0.2, frCorrespondent.VAT, 'Incorrect VAT for France correspondent');
    
        // Test case 4: Correspondent from TOM & Export
        OcoCorrespondentApi.Correspondent tomExportCorrespondent = new OcoCorrespondentApi.Correspondent();
        tomExportCorrespondent.Code = 'TOM123';
        tomExportCorrespondent.Name = 'TOM & Export Correspondent';
        tomExportCorrespondent.BillingCountryCode = 'TOM';
        tomExportCorrespondent.BillingCountry = 'TOM';
        tomExportCorrespondent = OcoCorrespondentApi.getCorrespondentBillingInformations(tomExportCorrespondent);
    
        System.assertEquals(tomExportPricebook.Id, tomExportCorrespondent.PricebookId, 'Incorrect PricebookId for TOM & Export correspondent');
        System.assertEquals(tomExportPricebook.Name, tomExportCorrespondent.PricebookName, 'Incorrect PricebookName for TOM & Export correspondent');
        System.assertEquals(0.25, tomExportCorrespondent.VAT, 'Incorrect VAT for TOM & Export correspondent');
    }

    @isTest
    static void testGetCorrespondentData() {

        // Create test data - Pricebooks
        Pricebook2 cerbaVetPricebook = new Pricebook2(Name = 'CerbaVet');
        Pricebook2 domPricebook = new Pricebook2(Name = 'CerbaVet DOM');
        Pricebook2 tomExportPricebook = new Pricebook2(Name = 'CerbaVet TOM et Export');
        insert new List<Pricebook2>{ cerbaVetPricebook, domPricebook, tomExportPricebook };
            
        // Create test data - Legal Entities
        blng__LegalEntity__c swissLegalEntity = new blng__LegalEntity__c(Name = 'Cerbavet Suisse');
        blng__LegalEntity__c franceLegalEntity = new blng__LegalEntity__c(Name = 'Cerbavet France');
        insert new List<blng__LegalEntity__c>{ swissLegalEntity, franceLegalEntity };
    
        // Create test data - Tax Rates
        blng__TaxRate__c franceVAT = new blng__TaxRate__c(blng__Rate__c = 0.2, blng__TaxCode__c = 'TRFM', blng__Priority__c = '1');
        blng__TaxRate__c swissVAT = new blng__TaxRate__c(blng__Rate__c = 0.1, blng__TaxCode__c = 'TRCH', blng__Priority__c = '1');
        blng__TaxRate__c domVAT = new blng__TaxRate__c(blng__Rate__c = 0.15, blng__TaxCode__c = 'TRDOM', blng__Priority__c = '1');
        blng__TaxRate__c exportVAT = new blng__TaxRate__c(blng__Rate__c = 0.25, blng__TaxCode__c = 'TRE', blng__Priority__c = '1');
        insert new List<blng__TaxRate__c>{ franceVAT, swissVAT, domVAT, exportVAT };

        // Create test data - Account
        Account testAccount = new Account();
        testAccount.Code_compte_metier__c = 'FR123';
        testAccount.Name = 'HEX-119-FR123-Clinique du petit bois';
        testAccount.Conditions_de_Reglement_Cerbavet__c = 'Non Régleur';
        testAccount.BillingCountry = 'France';
        testAccount.BillingCountryCode = 'FR';
        testAccount.SIRET__c = 123456789;
        testAccount.CurrencyIsoCode = 'EUR';
        insert testAccount;
    
        // Set up REST request and response
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.params.put('code', 'FR123');
    
        // Set the RestContext parameters
        RestContext.request = request;
        RestContext.response = response;
    
        // Call the method to be tested
        OcoCorrespondentApi.Correspondent result = OcoCorrespondentApi.getCorrespondentData();
    
        // Verify the response and returned Correspondent object
        System.assertEquals(200, response.statusCode, 'Incorrect status code');
        System.assertEquals('FR123', result.Code, 'Incorrect Correspondent Code');
        System.assertEquals('Clinique du petit bois', result.Name, 'Incorrect Correspondent Name');
        System.assertEquals(true, result.NonBillable, 'Incorrect NonBillable value');
        System.assertEquals('France', result.BillingCountry, 'Incorrect Billing Country');
        System.assertEquals('FR', result.BillingCountryCode, 'Incorrect Billing Country Code');
        System.assertEquals('123456789', result.Siret, 'Incorrect Siret value');
        System.assertEquals('EUR', result.CurrencyIsoCode, 'Incorrect Currency ISO Code');
    }

    @isTest
    static void testCorrespondentClass() {
        // Create a new instance of the Correspondent class
        OcoCorrespondentApi.Correspondent correspondent = new OcoCorrespondentApi.Correspondent();
        correspondent.Code = 'ABC123';
        correspondent.Name = 'Test Correspondent';
        correspondent.NonBillable = false;
        correspondent.BillingCountry = 'France';
        correspondent.BillingCountryCode = 'FR';
        correspondent.Siret = '123456789';
        correspondent.PricebookId = 'PB001';
        correspondent.PricebookName = 'Standard Pricebook';
        correspondent.VAT = 0.2;
        correspondent.CurrencyIsoCode = 'EUR';
        correspondent.BillingEntityId = 'BE001';
        correspondent.BillingEntityName = 'Test Billing Entity';
        correspondent.Email = 'test.correspondent@mail.com';
        correspondent.Address = '1 rue de Metz';
        correspondent.Zipcode = '54000';
        correspondent.City = 'Nancy';
        correspondent.CourierPrice = 10;
        correspondent.ReducedCourierPrice = 9.5;
        
        // Verify the getter methods
        System.assertEquals('ABC123', correspondent.Code, 'Code should be set correctly');
        System.assertEquals('Test Correspondent', correspondent.Name, 'Name should be set correctly');
        System.assertEquals(false, correspondent.NonBillable, 'NonBillable should be set correctly');
        System.assertEquals('France', correspondent.BillingCountry, 'BillingCountry should be set correctly');
        System.assertEquals('FR', correspondent.BillingCountryCode, 'BillingCountryCode should be set correctly');
        System.assertEquals('123456789', correspondent.Siret, 'Siret should be set correctly');
        System.assertEquals('PB001', correspondent.PricebookId, 'PricebookId should be set correctly');
        System.assertEquals('Standard Pricebook', correspondent.PricebookName, 'PricebookName should be set correctly');
        System.assertEquals(0.2, correspondent.VAT, 'VAT should be set correctly');
        System.assertEquals('EUR', correspondent.CurrencyIsoCode, 'CurrencyIsoCode should be set correctly');
        System.assertEquals('BE001', correspondent.BillingEntityId, 'BillingEntityId should be set correctly');
        System.assertEquals('Test Billing Entity', correspondent.BillingEntityName, 'BillingEntityName should be set correctly');
        System.assertEquals('test.correspondent@mail.com', correspondent.Email, 'Email should be set correctly');
        System.assertEquals('1 rue de Metz', correspondent.Address, 'Address should be set correctly');
        System.assertEquals('54000', correspondent.Zipcode, 'Zipcode should be set correctly');
        System.assertEquals('Nancy', correspondent.City, 'City should be set correctly');
        System.assertEquals(10, correspondent.CourierPrice, 'CourierPrice should be set correctly');
        System.assertEquals(9.5, correspondent.ReducedCourierPrice, 'ReducedCourierPrice should be set correctly');
    }
    
    @isTest
    static void testGetContentAfterTwoFirstHyphens() {
        // Test input strings
        String inputString1 = 'abc-efg-hij-klm';
        String inputString2 = 'abc-efg-hij-klm-nop';

        // Call the getContentAfterTwoFirstHyphens method
        String outputString1 = OcoCorrespondentApi.getContentAfterTwoFirstHyphens(inputString1);
        String outputString2 = OcoCorrespondentApi.getContentAfterTwoFirstHyphens(inputString2);

        // Assert the results
        System.assertEquals('klm', outputString1, 'Incorrect output string 1');
        System.assertEquals('klm-nop', outputString2, 'Incorrect output string 2');
    }
}