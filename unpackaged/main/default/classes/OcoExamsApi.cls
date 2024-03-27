@RestResource(urlMapping='/oco/exams')
global with sharing class OcoExamsApi {
    
    global class Market {
        public String Name { get; set; }
    }
   
    global class Specie {
        public String Name { get; set; }
        public String HexalisCode { get; set; }
    }
    
    global class Exam {
        
        /** Main informations **/
        public String Id { get; set; }
        public String Code { get; set; }
        public String Name { get; set; }
        public String Family { get; set; }
        public Specie[] Species { get; set; }
        public String Preanalytics { get; set; }
        public Boolean Favorite { get; set; }
        public Boolean NewExam { get; set; }
        // public Market[] Market { get; set; }
        public Boolean SubContracting { get; set; }
        public String RealizedAnalyses { get; set; }
        public String Description { get; set; }
        
        /** Detail informations **/
        public String Advices { get; set; }
        public String AdditionalInformations  { get; set; }
        public String SamplesQuantities  { get; set; }
        public String ProcessingDelay  { get; set; }
        public Boolean DegressivePrice { get; set; }
        public Double DegressivePriceAmount { get; set; }
        
        /* Custom field */
        public Boolean CustomFieldVisible { get; set; }
        public String CustomFieldLabel { get; set; }
    }
    
    // Method to convert species from multipick list string to List<Specie>
    public static List<Specie> getSpeciesList(String species)
    {
        // The str string is formatted like this "name;name;name;"
        List<Specie> speciesList = new List<Specie>();
        
        // Empty species handling
        if (species == null || species == '')
        {
	        return speciesList;
        }
        
        // Get a String list of species and loop through it
        List<String> stringList = species.split(';');
        for (Integer index = 0; index < stringList.size(); index++) 
        {
            // Add the specie to the speciesList if valid
            if (stringList[index] != null && stringList[index] != '')
            {
                // Split string to get 'specie,code'
                List<String> splittedString = stringList[index].split(',');
                
                // Error handling
                if (splittedString.size() > 0) {
                    Specie specie = new Specie();
                    specie.Name = splittedString[0]; 
                    specie.HexalisCode = (splittedString.size() > 1) ? splittedString[1] : ''; 
                    speciesList.add(specie);                
                }
            }
        }
        
        // Return created speciesList
        return speciesList;
    }
    
    // Endpoint to get all exams data
    @HttpGet
    global static List<Exam> getExams() {       
        // Get exams from Salesforce table
        List<Product2> result = [SELECT Id, ProductCode, Name, Family, Espece__c, Preanalytique__c,  
                                 Favorite__c, New__c, SubContracting__c, Analyses_realisees__c, Description, 
                                 Conseil__c, infos__c, Qte_souhaitee__c, Delai__c, Prix_degressif__c,
                                 oco_custom_field_visible__c, oco_custom_field_label__c
                                 FROM Product2 
                                 WHERE IsActive = true
                                 AND Visible_Catalogue__c = true];
        
        // Create custom exam object list
        List<Exam> examList = new List<Exam>();
        
        // Fill list with Salesforce data
        for (Integer index = 0; index < result.size(); index++) {
            // Create custom exam model
	        Exam exam = new Exam();
            
            // Main informations
			exam.Id = result[index].Id;
			exam.Code = result[index].ProductCode;
			exam.Name = result[index].Name;
			exam.Family = result[index].Family;
            exam.Species = getSpeciesList(result[index].Espece__c);
            exam.Preanalytics = result[index].Preanalytique__c;
			exam.Favorite = result[index].Favorite__c;
            exam.NewExam = result[index].New__c;
            // TODO: Market
			exam.SubContracting = result[index].SubContracting__c;
			exam.RealizedAnalyses = result[index].Analyses_realisees__c;  
			exam.Description = result[index].Description;  
            
            // Detais informations
			exam.Advices = result[index].Conseil__c;  
			exam.AdditionalInformations = result[index].infos__c;  
			exam.SamplesQuantities = result[index].Qte_souhaitee__c;  
			exam.ProcessingDelay = result[index].Delai__c;  
			exam.DegressivePrice = result[index].Prix_Degressif__c;  
            exam.DegressivePriceAmount = 0;
            
            // Custom field
			exam.CustomFieldVisible = result[index].oco_custom_field_visible__c;  
			exam.CustomFieldLabel = result[index].oco_custom_field_label__c;  
            
            // Add exam model to the list
            examList.add(exam);
        }

        // Return the created list
        return examList;
    }
}