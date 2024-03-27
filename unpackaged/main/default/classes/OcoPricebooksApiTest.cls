@isTest
private class OcoPricebooksApiTest {
    
    @isTest
    static void testGetPricebookEntries() {
        
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook2 = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Run an update DML on the Pricebook2 record
        // This is the weird workaround that enables IsStandard to become true
        // on the PricebookEntry record
        update standardPricebook2;

        // Create custom test product
        Product2 product = new Product2(Name = 'Test Product', ProductCode = 'TEST', IsActive = true);
        insert product;

        // Create a custom standard PricebookEntry
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook2.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
	        CurrencyIsoCode = 'EUR',
            IsActive = true
        );        
        insert standardPBE;
        
        // Call the method to test
        Test.startTest();
        List<OcoPricebooksApi.PricebookItem> pricebookItemsList = OcoPricebooksApi.getPricebookEntries();
        Test.stopTest();
        
        // Assert the results
        System.assertEquals(1, pricebookItemsList.size());
        OcoPricebooksApi.PricebookItem pricebookItem = pricebookItemsList[0];
        System.assertEquals(standardPricebook2.Id, pricebookItem.PricebookId);
        System.assertEquals(standardPBE.CurrencyIsoCode, pricebookItem.CurrencyIsoCode);
        System.assertEquals(standardPBE.UnitPrice, pricebookItem.UnitPrice);
        System.assertEquals(product.ProductCode, pricebookItem.ExamCode);
    }
    
    @isTest
    static void testPricebookItemClass() {
        // Create a new instance of the PricebookItem class
        OcoPricebooksApi.PricebookItem item = new OcoPricebooksApi.PricebookItem();
        item.PricebookId = '123456789'; // Set the PricebookId
        item.PricebookName = 'Test Pricebook'; // Set the PricebookName
        item.CurrencyIsoCode = 'USD'; // Set the CurrencyIsoCode
        item.UnitPrice = 9.99; // Set the UnitPrice
        item.ExamCode = 'EXAM001'; // Set the ExamCode
    
        // Verify the getter methods
        System.assertEquals('123456789', item.PricebookId, 'PricebookId should be set correctly');
        System.assertEquals('Test Pricebook', item.PricebookName, 'PricebookName should be set correctly');
        System.assertEquals('USD', item.CurrencyIsoCode, 'CurrencyIsoCode should be set correctly');
        System.assertEquals(9.99, item.UnitPrice, 'UnitPrice should be set correctly');
        System.assertEquals('EXAM001', item.ExamCode, 'ExamCode should be set correctly');
    }
}