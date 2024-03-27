global inherited sharing class MensualiteBatch implements Database.Batchable<sObject>, Database.Stateful {

    private List<Cout_de_transport__c> coutTransportList;
    
    global MensualiteBatch() {
        this.coutTransportList = CoutTransportService.checkCoutForGeneration(CoutTransportDao.getAllCurrentCouts());
    }
    
    global Iterable<sObject> start(Database.BatchableContext bc) {
        System.debug('MensualiteBatch start');
        return this.coutTransportList;
    }

    global void execute(Database.BatchableContext bc, List<Cout_de_transport__c> coutTransportList) {
        List<Mensualite__c> mensualites = new List<Mensualite__c>();
        
        for(Cout_de_transport__c coutTransport : coutTransportList){
    		mensualites.addAll(MensualiteService.generateMensualites(coutTransport));
        }
        
        if(mensualites.size() > 0){
            insert mensualites;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('MensualiteBatch finish');
    }
    
}