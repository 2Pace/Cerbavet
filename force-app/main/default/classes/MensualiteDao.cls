public inherited sharing class MensualiteDao {

    public static List<Mensualite__c> getMensualitesFromCoutAndDate(Id coutTransportId, Date dateFin){
        return [Select Id, Cout_de_transport__c, Date_de_la_mensualite__c, Montant_provisionne_TTC__c 
                From Mensualite__c 
                Where Cout_de_transport__c = :coutTransportId and Date_de_la_mensualite__c >= :dateFin];
    }
    
    public static List<Mensualite__c> getCurrentMensualite(List<Id> cdtsId){
        return [Select Id, Cout_de_transport__c, Date_de_la_mensualite__c, Montant_provisionne_TTC__c 
                From Mensualite__c 
                Where Cout_de_transport__c in :cdtsId and Date_de_la_mensualite__c >= :system.today() 
                	and Date_de_la_mensualite__c <= :system.today().addYears(1)];
    }
    
}