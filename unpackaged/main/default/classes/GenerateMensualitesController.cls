public inherited sharing class GenerateMensualitesController {

    @AuraEnabled
    public static void generateAllMensualites(){
        // Vérification que le batch n'est pas déjà en cours avant execution.
        ApexClass apexClass = [SELECT Id, Name FROM ApexClass WHERE Name = :MensualiteBatch.class.getName()];
        List<AsyncapexJob> apexJobs = [SELECT Id, Status FROM AsyncapexJob WHERE ApexClassID = :apexClass.Id order by CreatedDate DESC limit 1];
        if(apexJobs.size() == 0 || apexJobs.get(0).Status == 'Completed'){
            MensualiteBatch batch = new MensualiteBatch();
            Database.executeBatch(batch);
        }
    }
    
}