@isTest
private class OcoSpeciesApiTest {
    
    @isTest
    static void testSpecieClass() {
        // Create a new Specie instance
        OcoSpeciesApi.Specie specie = new OcoSpeciesApi.Specie();
        
        // Set the property values
        specie.Name = 'Chat';
        specie.HexalisCode = 'CHAT';
        
        // Verify the property values are set correctly
        System.assertEquals('Chat', specie.Name, 'Incorrect species name');
        System.assertEquals('CHAT', specie.HexalisCode, 'Incorrect species Hexalis code');
    }
    
    @isTest
    static void testGetSpecies() {
        // Create test data
        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.Espece__c = 'Chat,CHAT';
        insert product;
        
        // Call the getSpecies method
        List<OcoSpeciesApi.Specie> speciesList = OcoSpeciesApi.getSpecies();
               
        // Assert the results
        Boolean speciesNameExists = false;
        for (OcoSpeciesApi.Specie species : speciesList) {
            if (species.Name == 'Chat') {
                speciesNameExists = true;
                System.assertEquals('CHAT', species.HexalisCode, 'Incorrect specie Hexalis code');
                break;
            }
        }
	    System.assertEquals(true, speciesNameExists, 'The species with the name "Chat" does not exist in the species list');
    }
}