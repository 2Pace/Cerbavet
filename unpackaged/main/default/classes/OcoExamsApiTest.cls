@isTest
private class OcoExamsApiTest {    
    @isTest
    static void testGetExams() {
        // Create test data
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
            Product2 product = new Product2(
                ProductCode = 'EX00' + i,
                Name = 'Test Exam ' + i,
                Family = 'Test Family ' + i,
                Espece__c = 'Chat,CHAT',
                Favorite__c = true,
                New__c = false,
                SubContracting__c = true,
                Analyses_realisees__c = 'Test Realized Analyses ' + i,
                Description = 'Test Description ' + i,
                Conseil__c = 'Test Advices ' + i,
                infos__c = 'Test Additional Informations ' + i,
                Qte_souhaitee__c = 'Test Samples Quantities ' + i,
                Delai__c = 'Test Processing Delay ' + i,
                Prix_Degressif__c = true,
                IsActive = true,
                Visible_Catalogue__c = true
            );
            products.add(product);
        }
        insert products;

        // Call the controller method
        Test.startTest();
        List<OcoExamsApi.Exam> result = OcoExamsApi.getExams();
        Test.stopTest();

        // Verify the results
        System.assertEquals(3, result.size(), 'Expected 3 Exam objects');
        for (Integer i = 0; i < result.size(); i++) {
            OcoExamsApi.Exam exam = result[i];
            Product2 product = products[i];
            System.assertEquals(product.Id, exam.Id);
            System.assertEquals(product.ProductCode, exam.Code);
            System.assertEquals(product.Name, exam.Name);
            System.assertEquals(product.Family, exam.Family);
            // Verify the Species list
            System.assertEquals(1, exam.Species.size(), 'Expected 1 Specie in the list');
            System.assertEquals(product.Favorite__c, exam.Favorite);
            System.assertEquals(product.New__c, exam.NewExam);
            // TODO: Verify Market
            System.assertEquals(product.SubContracting__c, exam.SubContracting);
            System.assertEquals(product.Analyses_realisees__c, exam.RealizedAnalyses);
            System.assertEquals(product.Description, exam.Description);
            System.assertEquals(product.Conseil__c, exam.Advices);
            System.assertEquals(product.infos__c, exam.AdditionalInformations);
            System.assertEquals(product.Qte_souhaitee__c, exam.SamplesQuantities);
            System.assertEquals(product.Delai__c, exam.ProcessingDelay);
            System.assertEquals(product.Prix_Degressif__c, exam.DegressivePrice);
            System.assertEquals(0.0, exam.DegressivePriceAmount);
        }
    }
    
    @isTest
    static void testGetSpeciesList() {
        // Set the species parameter
        String speciesParam = 'Chat;Chien;Lagomorphe;Dauphin';

        // Call the method
        List<OcoExamsApi.Specie> result = OcoExamsApi.getSpeciesList(speciesParam);

        // Verify the result
        System.assertEquals(4, result.size(), 'Expected 4 species in the list');

        // Verify the species names
        System.assertEquals('Chat', result[0].Name);
        System.assertEquals('Chien', result[1].Name);
        System.assertEquals('Lagomorphe', result[2].Name);
        System.assertEquals('Dauphin', result[3].Name);
    }
    
    @isTest
    static void testMarketClass() {
        // Create a new instance of the Market class
        OcoExamsApi.Market market = new OcoExamsApi.Market();
        market.Name = 'Test Market';

        // Verify the getter method
        System.assertEquals('Test Market', market.Name, 'Name should be set correctly');
    }
    
    @isTest
    static void testSpecieClass() {
        // Create a new instance of the Specie class
        OcoExamsApi.Specie specie = new OcoExamsApi.Specie();
        specie.Name = 'Chat';
        specie.HexalisCode = 'CHAT';

        // Verify the getter method
        System.assertEquals('Chat', specie.Name, 'Name should be set correctly');
        System.assertEquals('CHAT', specie.HexalisCode, 'Name should be set correctly');
    }
    
    @isTest
    static void testExamClass() {
        // Create an instance of the Exam class
        OcoExamsApi.Exam exam = new OcoExamsApi.Exam();
        
        // Set values for the properties
        exam.Id = '001ABC';
        exam.Code = 'EX001';
        exam.Name = 'Test Exam';
        exam.Family = 'Test Family';
        exam.Species = new OcoExamsApi.Specie[]{};
        exam.Preanalytics = 'Test Preanalytics';
        exam.Favorite = true;
        exam.NewExam = false;
        exam.SubContracting = true;
        exam.RealizedAnalyses = 'Test Realized Analyses';
        exam.Description = 'Test Description';
        exam.Advices = 'Test Advices';
        exam.AdditionalInformations = 'Test Additional Informations';
        exam.SamplesQuantities = 'Test Samples Quantities';
        exam.ProcessingDelay = 'Test Processing Delay';
        exam.DegressivePrice = true;
        exam.DegressivePriceAmount = 10.0;

        // Verify the getter methods
        System.assertEquals('001ABC', exam.Id, 'Id should be set correctly');
        System.assertEquals('EX001', exam.Code, 'Code should be set correctly');
        System.assertEquals('Test Exam', exam.Name, 'Name should be set correctly');
        System.assertEquals('Test Family', exam.Family, 'Family should be set correctly');
        System.assertEquals(new OcoExamsApi.Specie[]{}, exam.Species, 'Species should be set correctly');
        System.assertEquals('Test Preanalytics', exam.Preanalytics, 'Preanalytics should be set correctly');
        System.assertEquals(true, exam.Favorite, 'Favorite should be set correctly');
        System.assertEquals(false, exam.NewExam, 'NewExam should be set correctly');
        System.assertEquals(true, exam.SubContracting, 'SubContracting should be set correctly');
        System.assertEquals('Test Realized Analyses', exam.RealizedAnalyses, 'RealizedAnalyses should be set correctly');
        System.assertEquals('Test Description', exam.Description, 'Description should be set correctly');
        System.assertEquals('Test Advices', exam.Advices, 'Advices should be set correctly');
        System.assertEquals('Test Additional Informations', exam.AdditionalInformations, 'AdditionalInformations should be set correctly');
        System.assertEquals('Test Samples Quantities', exam.SamplesQuantities, 'SamplesQuantities should be set correctly');
        System.assertEquals('Test Processing Delay', exam.ProcessingDelay, 'ProcessingDelay should be set correctly');
        System.assertEquals(true, exam.DegressivePrice, 'DegressivePrice should be set correctly');
        System.assertEquals(10.0, exam.DegressivePriceAmount, 'DegressivePriceAmount should be set correctly');
    }
}