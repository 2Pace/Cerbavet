@isTest
private class OcoBillingCountriesApiTest {

    @isTest
    static void testGetBillingCountries() {
        // Create test data
        List<blng__TaxRate__c> taxRates = new List<blng__TaxRate__c>();
        for (Integer i = 0; i < 5; i++) {
            blng__TaxRate__c taxRate = new blng__TaxRate__c(
                blng__Country__c = 'France',
                blng__Rate__c = 20.5,
                blng__Priority__c = '0'
            );
            taxRates.add(taxRate);
        }
        insert taxRates;

        // Call the controller method
        Test.startTest();
        List<OcoBillingCountriesApi.BillingCountry> result = OcoBillingCountriesApi.getBillingCountries();
        Test.stopTest();

        // Verify the results
        System.assertEquals(5, result.size(), 'Expected 5 BillingCountry objects');
        for (Integer i = 0; i < result.size(); i++) {
            OcoBillingCountriesApi.BillingCountry billingCountry = result[i];
            blng__TaxRate__c taxRate = taxRates[i];
            System.assertEquals('France', billingCountry.Name);
            System.assertEquals(20.5, billingCountry.VAT);
        }
    }

    @isTest
    static void testBillingCountryClass() {
        // Create a new instance of the BillingCountry class
        OcoBillingCountriesApi.BillingCountry billingCountry = new OcoBillingCountriesApi.BillingCountry();
        billingCountry.Name = 'USA';
        billingCountry.VAT = 20.5;
        billingCountry.LegalEntityName = 'Test Legal Entity';
        billingCountry.LegalEntityNumber = '001ABC';

        // Verify the getter methods
        System.assertEquals('USA', billingCountry.Name, 'Name should be set correctly');
        System.assertEquals(20.5, billingCountry.VAT, 'VAT should be set correctly');
        System.assertEquals('Test Legal Entity', billingCountry.LegalEntityName, 'LegalEntityName should be set correctly');
        System.assertEquals('001ABC', billingCountry.LegalEntityNumber, 'LegalEntityNumber should be set correctly');
    }
}