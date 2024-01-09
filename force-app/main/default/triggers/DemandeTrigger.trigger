trigger DemandeTrigger on Demande__c (after update) {
    static String STATUT_VALIDE = 'Validée par la direction commerciale';
    
    List<Demande__c> demandes = new List<Demande__c>();
    List<Id> coutsId = new List<Id>();
    for(Demande__c demande : trigger.new){
        if(demande.Statut__c == STATUT_VALIDE && trigger.oldMap.get(demande.Id).Statut__c != STATUT_VALIDE){
            demandes.add(demande);
        	coutsId.add(demande.Facture_directe__c);
        }
    }
    
    if(demandes.size() > 0){
    	Map<Id, Cout_de_transport__c> cdtsById = CoutTransportService.getMapCoutsByIds(coutsId);
        // Mise a jour des couts lorsqu'une demande de modification est validée.
        CoutTransportService.updateFromDemande(demandes, cdtsById);
        // Mise a jour ou suppression des mensualités lorsqu'une demande de modification ou de suppression est validée.
        MensualiteService.updateOrDeleteFromDemande(demandes, cdtsById);
    }

}