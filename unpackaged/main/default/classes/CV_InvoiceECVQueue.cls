/**
 * Created by Michael on 26-08-22.
 */

public with sharing class CV_InvoiceECVQueue implements Queueable, Database.AllowsCallouts {

    private List<CV_Intf_InvoiceSchemaBuilder> bodyRequestMapListClinic;

    public CV_InvoiceECVQueue(List<CV_Intf_InvoiceSchemaBuilder> bodyRequestMapListClinic) {

        this.bodyRequestMapListClinic = bodyRequestMapListClinic;

    }

    public void execute(QueueableContext param) {

        System.debug('========================= CV_InvoiceECVQueue bodyRequestMapListClinic #: ' + bodyRequestMapListClinic.size());
        CV_Intf_InvoiceSchemaBuilder payloadToSend;

        if (bodyRequestMapListClinic != null) {
            if (!bodyRequestMapListClinic.isEmpty()) {
                payloadToSend = bodyRequestMapListClinic.remove(0);
            }

            if (payloadToSend != null && payloadToSend.attachment != null) {
                try {
                    ContentVersion contentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :payloadToSend.attachment];
                    payloadToSend.attachment = EncodingUtil.base64Encode(contentVersion.VersionData);

                } catch (Exception e) {
                    System.debug('========================== CV_InvoiceECVQueue Erreur: ' + e.getMessage());
                }
            }

            CV_Intf_WebserviceCalloutECV wsECVCallout = new CV_Intf_WebserviceCalloutECV();
            wsECVCallout.sendStructuresToECV(new List<Object>{payloadToSend});

            if (!bodyRequestMapListClinic.isEmpty()) {
                System.enqueueJob(new CV_InvoiceECVQueue(bodyRequestMapListClinic));
            }
        }
    }

}