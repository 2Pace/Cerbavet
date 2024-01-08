/**
 * Created by Michael on 09-11-23.
 */

trigger InvoiceRunTriger on blng__InvoiceRun__c (after update) {

    if (Trigger.isUpdate && Trigger.isAfter) {
        InvoiceRunTriggerHandler.calculateInvoiceNumber(Trigger.newMap, Trigger.oldMap);
    }

}