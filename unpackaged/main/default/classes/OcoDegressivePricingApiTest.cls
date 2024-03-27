@isTest
private class OcoDegressivePricingApiTest {

    @isTest
    static void testDegressivePrice() {
        // Create test data
        OcoDegressivePricingApi.DegressivePrice price = new OcoDegressivePricingApi.DegressivePrice();
        price.Name = 'Test Price';
        price.Discount = 0.2;
        price.LowerBound = 1;
        price.UpperBound = 10;
        
        // Test getters and setters
        System.assertEquals('Test Price', price.Name);
        System.assertEquals(0.2, price.Discount);
        System.assertEquals(1, price.LowerBound);
        System.assertEquals(10, price.UpperBound);
    }
    
    @isTest
    static void testDecimalToInt() {
        // Test case 1: Valid decimal input
        Decimal validDecimal = 10.6;
        Integer expectedOutput = 11;
        Integer actualOutput = OcoDegressivePricingApi.decimalToInt(validDecimal);
        System.assertEquals(expectedOutput, actualOutput);

        // Test case 2: Decimal input with no fractional part
        Decimal wholeNumber = 15.0;
        expectedOutput = 15;
        actualOutput = OcoDegressivePricingApi.decimalToInt(wholeNumber);
        System.assertEquals(expectedOutput, actualOutput);

        // Test case 3: Negative decimal input
        Decimal negativeDecimal = -8.9;
        expectedOutput = -9;
        actualOutput = OcoDegressivePricingApi.decimalToInt(negativeDecimal);
        System.assertEquals(expectedOutput, actualOutput);

        // Test case 4: Exception handling
        Decimal invalidDecimal = null;
        expectedOutput = 0;
        Test.startTest();
        Integer actualOutputException = OcoDegressivePricingApi.decimalToInt(invalidDecimal);
        Test.stopTest();
        System.assertEquals(expectedOutput, actualOutputException);
    }
    
    @isTest
    static void testGetDegressivePrices() {

        // Call the method under test
        Test.startTest();
        List<OcoDegressivePricingApi.DegressivePrice> result = OcoDegressivePricingApi.getDegressivePrices();
        Test.stopTest();

        // Assert the result
        Boolean degressivePriceNameExists = false;
        for (OcoDegressivePricingApi.DegressivePrice item : result) {
            if (item.Name == 'X1_Code') {
                degressivePriceNameExists = true;
                System.assertEquals('X1_Code', item.Name, 'Incorrect name');
                break;
            }
        }
	    System.assertEquals(true, degressivePriceNameExists, 'The DegressivePrice with the name "X1_Code" does not exist in the species list');
    }
}