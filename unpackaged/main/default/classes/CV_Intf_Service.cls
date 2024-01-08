/**
 * @description       : Classe de service pour gestion/mapping des interfaces avec les systèmes extérieurs
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 02-06-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_Intf_Service {

    public static final String API_FIELDNAME_NOT_FOUND = 'Field API Name Not found: ';
    public static final String FIELDNAME_NO_MAPPING = 'Champ non trouvé dans le mapping ';

    public static Map<String, String> apiFieldNameByDeveloperName = new Map<String, String>();
    public static List<String> falseFieldsDevName = new List<String>();
    public static Map<String, Intf_Sync_Field__mdt> syncFieldRecordByDeveloperName = new Map<String, Intf_Sync_Field__mdt>();
    public static Map<String,Map<String,String>> mapTransfFields = new Map<String,Map<String,String>>();

    /**
    * Exception thrown when a Sync Field is not found or the name it's incorrect
    */
    public class NoFoundFieldException extends Exception {}

    /**
    * Generates a unique Message Id for every HTTP callout made to MDW
    * @return   The unique message Id
    */
    public static String getUMessageId() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8) + h.SubString(8,12) + h.SubString(12,16) + h.SubString(16,20);

        System.debug(' --------------------------   Unique Message Id: ' + guid);
        return guid;
    }

    /**
     * Get all the fields in Sync Field Custom Metadata Type that are active to be sent to MDW
     * @return   The list of active fields
     */
    public static List<Intf_Sync_Field__mdt> getActiveSyncFields(String targetSystem) {

        List<Intf_Sync_Field__mdt> SyncFieldsList = new List<Intf_Sync_Field__mdt>();

        List <Intf_Sync_Field__mdt> listSyncFields= [
                SELECT Object__c, SFDC_API_Name__c, DeveloperName, Active__c, Related_object__c
                FROM Intf_Sync_Field__mdt
                WHERE Target_System__c =: targetSystem
        ]
        ;
        for(Intf_Sync_Field__mdt SyncField: listSyncFields){

            if(SyncField.Active__c){
                SyncFieldsList.add(SyncField);
                apiFieldNameByDeveloperName.put(SyncField.DeveloperName, SyncField.SFDC_API_Name__c);
                syncFieldRecordByDeveloperName.put(SyncField.DeveloperName, SyncField);

            } else {
                falseFieldsDevName.add(SyncField.DeveloperName);
            }
        }
        return SyncFieldsList;
    }

    /**
     * Get the value for the related Sync Field in the record SObject
     * @param record The record where the value should be retrieved
     * @param fieldName The Sync Field Custom Metadata DeveloperName
     * @return The value of the record Field if any. Returns a blank String if the value is null
     */
    public static String getSObjectFieldValue(SObject record, String fieldName){

        String returnValue = '';

        if(!falseFieldsDevName.contains(fieldName)){

            if(apiFieldNameByDeveloperName.containsKey(fieldName)) {

                try {

                    if(record.isSet(apiFieldNameByDeveloperName.get(fieldName))) {
                        returnValue = String.valueOf(record.get(apiFieldNameByDeveloperName.get(fieldName)));
                    } else {
                        returnValue = '';
                    }

                } catch(Exception e) {
                    e.setMessage(API_FIELDNAME_NOT_FOUND + fieldName);
                }
            } else {
                throw new NoFoundFieldException(FIELDNAME_NO_MAPPING + fieldName);
            }
        } else {
            returnValue = '';
        }

        return returnValue;
    }

    /**
     * Get the value for a Synced Field in the related record SObject
     * @param record The record where the value should be retrieved
     * @param fieldName The Lookup Sync Field Custom Metadata DeveloperName
     * @return The value of the lookup record Field if any. Returns a blank String if the value is null
     */
    public static String getRelatedSObjectFieldValue(SObject record, String fieldName){

        String returnValue;

        if(!falseFieldsDevName.contains(fieldName)){

            if(syncFieldRecordByDeveloperName.containsKey(fieldName)) {

                Intf_Sync_Field__mdt mdtRecord = syncFieldRecordByDeveloperName.get(fieldName);
                String sfdcAPINameFieldString = mdtRecord.SFDC_API_Name__c;
                List<String> sfdcAPINameSplitList = sfdcAPINameFieldString.split('\\.');

                SObject relatedObject;
                SObject relatedObjectToSearch = record;

                for(Integer i = 0; i < sfdcAPINameSplitList.size()-1; i++){

                    if(relatedObjectToSearch != null){
                        String lookupField = sfdcAPINameSplitList[i];
                        relatedObject = relatedObjectToSearch.getSObject(lookupField);
                        relatedObjectToSearch = relatedObject;

                    } else {
                        break;
                    }
                }

                String sfdcAPINameRelatedObject = sfdcAPINameSplitList[sfdcAPINameSplitList.size()-1];

                if(relatedObject != null){

                    try {
                        if(relatedObject.get(sfdcAPINameRelatedObject) != '' && relatedObject.get(sfdcAPINameRelatedObject) != null) {
                            returnValue = String.valueOf(relatedObject.get(sfdcAPINameRelatedObject));
                        } else {
                            returnValue = '';
                        }

                    } catch(Exception e) {
                        e.setMessage(API_FIELDNAME_NOT_FOUND + fieldName);
                    }
                } else {
                    returnValue = '';
                }

            } else {
                throw new NoFoundFieldException(FIELDNAME_NO_MAPPING + fieldName);
            }

        } else {
            returnValue = '';
        }

        return returnValue;
    }

    /**
     * Get the value for the related Sync Field in the record SObject
     * @param record The record where the value should be retrieved to be transformed
     * @param fieldName The Sync Field Custom Metadata DeveloperName of the field to be transformed
     * @return The value of the record Field transformed if it has their transformation. Returns a blank String if
     *  there's no transformation for the value
     */
    public static String getTransformationValue(SObject record, String fieldName) {

        String sfdcValue = getSObjectFieldValue(record, fieldName);
        String sfdcAPIName = apiFieldNameByDeveloperName.get(fieldName);

        if(mapTransfFields.containsKey(sfdcAPIName)) {
            return mapTransfFields.get(sfdcAPIName).get(sfdcValue);
        } else {
            return '';
        }
    }

    /**
     * Load public Map of transformation values from Custom Metadata Type
     */
    public static void loadMDWTransformationsMap(String interfaceName) {
        if(mapTransfFields.isEmpty()) {
            mapTransfFields = getAllMDWFieldValuesTransformations(interfaceName);
        }

    }

    /**
    * Get all the transformation values in Interface Mapping Information
    * Custom Metadata Type for MDW interface
    * @return   The map of transformation values
    */
    public static Map<String,Map<String,String>> getAllMDWFieldValuesTransformations(String interfaceName){

        Map<String,Map<String,String>> fieldTransfValuesByField = new Map<String,Map<String,String>>();

        List<Intf_Transco__mdt> transformations = [
                SELECT SF_Field_Name__c, SF_Field_Value__c, Intf_Tag_Name__c, Intf_Tag_Value__c, Interface__r.DeveloperName
                FROM Intf_Transco__mdt
                WHERE Interface__r.DeveloperName = :interfaceName
        ];
        System.debug(' -------------------------- Intf_MDWService transformations :' + transformations);


        for (Intf_Transco__mdt mappInf : transformations) {
            if (!fieldTransfValuesByField.containsKey(mappInf.SF_Field_Name__c)) {
                fieldTransfValuesByField.put(mappInf.SF_Field_Name__c, new Map<String,String>());
            }

            fieldTransfValuesByField.get(mappInf.SF_Field_Name__c).put(
                    mappInf.SF_Field_Value__c,
                    mappInf.INTF_Tag_Value__c
            );
        }
        System.debug(' -------------------------- Intf_MDWService fieldTransfValuesByField :' + fieldTransfValuesByField);

        return fieldTransfValuesByField;
    }

    /**
     * Format the incoming Date to a MDW understandable format
     * @param record The SObject record to get the value
     * @param fieldName The SFDC Date field to be formatted
     * @return The Date in string format: DDMMYY
     */
    public static String getDateStringFormatted(SObject record, String fieldName){
        String dateFormatted = '';
        String datetimeStr = getSObjectFieldValue(record,fieldName);
        if(datetimeStr != null){
            dateFormatted = String.valueOf(Datetime.valueOf(datetimeStr).date());
        }
        // return dateFormatted.remove('-');
        return dateFormatted;
    }

}