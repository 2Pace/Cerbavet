@isTest
private class OcoBillingEntitiesApiTest {

    @isTest
    static void testGetBillingEntities() {
        // Create test data
        List<blng__LegalEntity__c> legalEntities = new List<blng__LegalEntity__c>();
        for (Integer i = 0; i < 5; i++) {
            blng__LegalEntity__c legalEntity = new blng__LegalEntity__c(
                blng__Country__c = 'USA',
                Name = 'Test Legal Entity ' + i,
                CurrencyIsoCode = 'EUR',
                blng__Street1__c = '123 Main St',
                blng__Street2__c = 'Apt 4B',
                blng__City__c = 'New York',
                blng__ZipPostalCode__c = '12345',
                blng__County__c = 'County',
                blng__State__c = 'NY'
            );
            legalEntities.add(legalEntity);
        }
        insert legalEntities;

        // Call the controller method
        Test.startTest();
        List<OcoBillingEntitiesApi.BillingEntity> result = OcoBillingEntitiesApi.getBillingEntities();
        Test.stopTest();

        // Verify the results
        System.assertEquals(5, result.size(), 'Expected 5 BillingEntity objects');
        for (Integer i = 0; i < result.size(); i++) {
            OcoBillingEntitiesApi.BillingEntity billingEntity = result[i];
            blng__LegalEntity__c legalEntity = legalEntities[i];
            System.assertEquals('USA', billingEntity.BillingCountry);
            System.assertEquals('Test Legal Entity ' + i, billingEntity.Name);
            System.assertEquals('EUR', billingEntity.CurrencyIsoCode);
            System.assertEquals('123 Main St', billingEntity.Street1);
            System.assertEquals('Apt 4B', billingEntity.Street2);
            System.assertEquals('New York', billingEntity.City);
            System.assertEquals('12345', billingEntity.PostalCode);
            System.assertEquals('County', billingEntity.County);
            System.assertEquals('NY', billingEntity.State);
            System.assertEquals('', billingEntity.PhoneNumber);
            System.assertEquals('', billingEntity.Email);
        }
    }
    
    @isTest
    static void testBillingEntityClass() {
        // Create a new instance of the BillingEntity class
        OcoBillingEntitiesApi.BillingEntity billingEntity = new OcoBillingEntitiesApi.BillingEntity();
        billingEntity.BillingCountry = 'USA';
        billingEntity.LegalEntityNumber = '001ABCDEF123456789';
        billingEntity.Name = 'Test Billing Entity';
        billingEntity.CurrencyIsoCode = 'EUR';
        billingEntity.Street1 = '123 Main St';
        billingEntity.Street2 = 'Apt 4B';
        billingEntity.City = 'New York';
        billingEntity.PostalCode = '12345';
        billingEntity.County = 'County';
        billingEntity.State = 'NY';
        billingEntity.PhoneNumber = '123-456-7890';
        billingEntity.Email = 'test@example.com';

        // Verify the getter methods
        System.assertEquals('USA', billingEntity.BillingCountry, 'BillingCountry should be set correctly');
        System.assertEquals('001ABCDEF123456789', billingEntity.LegalEntityNumber, 'LegalEntityNumber should be set correctly');
        System.assertEquals('Test Billing Entity', billingEntity.Name, 'Name should be set correctly');
        System.assertEquals('EUR', billingEntity.CurrencyIsoCode, 'CurrencyIsoCode should be set correctly');
        System.assertEquals('123 Main St', billingEntity.Street1, 'Street1 should be set correctly');
        System.assertEquals('Apt 4B', billingEntity.Street2, 'Street2 should be set correctly');
        System.assertEquals('New York', billingEntity.City, 'City should be set correctly');
        System.assertEquals('12345', billingEntity.PostalCode, 'PostalCode should be set correctly');
        System.assertEquals('County', billingEntity.County, 'County should be set correctly');
        System.assertEquals('NY', billingEntity.State, 'State should be set correctly');
        System.assertEquals('123-456-7890', billingEntity.PhoneNumber, 'PhoneNumber should be set correctly');
        System.assertEquals('test@example.com', billingEntity.Email, 'Email should be set correctly');
    }
}