public inherited sharing class CoutTransportDao {

    public static List<Cout_de_transport__c> getCoutsByIds(List<Id> coutsId){
        return [Select Id, Name, Cout_mensuel_attendu_TTC__c, Date_de_demarrage__c, Date_de_fin__c 
                                        From Cout_de_transport__c
                                        Where Id in :coutsId];
    }
    
    public static List<Cout_de_transport__c> getAllCurrentCouts(){
        return [Select Id, Name, Cout_mensuel_attendu_TTC__c, Date_de_demarrage__c, Date_de_fin__c 
                From Cout_de_transport__c
                Where (CALENDAR_YEAR(Date_de_fin__c) >= :system.today().year() or Date_de_fin__c = null) and Statut__c = :CoutTransportService.STATUT_VALIDE];
    }
    
}