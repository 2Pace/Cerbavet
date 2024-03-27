@isTest
private class OcoHandlingFeesApiTest {
	@isTest
    static void testHandlingFeeItem() {
        // Create a new HandlingFeeItem instance
        OcoHandlingFeesApi.HandlingFeeItem item = new OcoHandlingFeesApi.HandlingFeeItem();
        item.PricebookId = 'Test Pricebook Id';
        item.PricebookName = 'Test Pricebook Name';
        item.UnitPrice = 10.00;
        item.ExamCode = 'Test Exam Code';
        item.ExamName = 'Test Exam Name';

        // Perform assertions to verify the values
        System.assertEquals('Test Pricebook Id', item.PricebookId);
        System.assertEquals('Test Pricebook Name', item.PricebookName);
        System.assertEquals(10.00, item.UnitPrice);
        System.assertEquals('Test Exam Code', item.ExamCode);
        System.assertEquals('Test Exam Name', item.ExamName);
    }
    
	@isTest
    static void testGetHandlingFees() {
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
        Product2 testProduct = new Product2(Name = 'Test Product', ProductCode = 'FDD8');
        insert testProduct;
        
        // Create a test PricebookEntry and insert it
        PricebookEntry testPricebookEntry = new PricebookEntry(Pricebook2Id = standardPricebook2.Id,
                                                               Product2Id = testProduct.Id,
                                                               UnitPrice = 10);
        insert testPricebookEntry;

        // Call the getHandlingFees method
        List<OcoHandlingFeesApi.HandlingFeeItem> handlingFees = OcoHandlingFeesApi.HandlingFeeItem.getHandlingFees();
        
        // Perform assertions to verify the result
        System.assertEquals(1, handlingFees.size());
        OcoHandlingFeesApi.HandlingFeeItem handlingFee = handlingFees[0];
        System.assertEquals(standardPricebook2.Id, handlingFee.PricebookId);
        System.assertEquals(10, handlingFee.UnitPrice);
        System.assertEquals(testProduct.ProductCode, handlingFee.ExamCode);
        System.assertEquals(testProduct.Name, handlingFee.ExamName);
    }
}