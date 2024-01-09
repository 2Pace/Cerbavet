trigger CoutTransportTrigger on Cout_de_transport__c (after update) {

    // Creation des mensualités lorsque le cout de transport est validé.
    List<Cout_de_transport__c> cdts = CoutTransportDao.getCoutsByIds(new List<Id>(trigger.newMap.keySet()));
    List<Cout_de_transport__c> coutToGenerate = new List<Cout_de_transport__c>();
    for(Cout_de_transport__c cdt : cdts){
        if(trigger.newMap.get(cdt.Id).Statut__c == CoutTransportService.STATUT_VALIDE 
           		&& trigger.oldMap.get(cdt.Id).Statut__c != CoutTransportService.STATUT_VALIDE){
        	coutToGenerate.add(cdt);
        }
    }
    
    List<Mensualite__c> mensualites = new List<Mensualite__c>();
    for(Cout_de_transport__c cdt : CoutTransportService.checkCoutForGeneration(coutToGenerate)){
        mensualites.addAll(MensualiteService.generateMensualitesTrigger(cdt));
    }
    if(mensualites.size() > 0){
    	insert mensualites;
    }
    
}