/**
 * @description       : Class de service utilisée pour le calcul des numéros de facture
 * @author            : Michaël Cabaraux
 * @group             :
 * @last modified on  : 15-10-2022
 * @last modified by  : Michaël Cabaraux
**/

public with sharing class CV_InvoiceService {

    public static final Map<String, String> INVOICEPREFIX_BY_TYPES = new Map<String, String> {
            'Cerbavet' => 'FACCV',
            'Cerbavet Suisse' => 'FACCH',
            'Cerbavet College' => 'FACCC'
    };


    public static void recaculateNumbering(String invoiceType, Datetime runningDate) {

        String queryRunName = getRunNameQueryString(invoiceType);
        List<blng__Invoice__c> invoicesToUpdate = new List<blng__Invoice__c>();

        String currentDateFormatted = '' + runningDate.year() + String.valueOf(runningDate.month()).leftPad(2, '0') + String.valueOf(runningDate.day()).leftPad(2, '0');
        String dateFormatted = runningDate.year() + '-' + String.valueOf(runningDate.month()).leftPad(2, '0') + '-' + String.valueOf(runningDate.day()).leftPad(2, '0');
        String dateStart = dateFormatted + 'T00:00:01.00Z';
        String dateEnd = dateFormatted + 'T23:59:59.00Z';

        System.debug('========================== CV_InvoiceService recaculateNumbering queryRunName: ' + queryRunName);

        if (queryRunName != null) {
            String query = 'SELECT Id, Numero_Facturation_Cerbavet__c ';
            query += 'FROM blng__Invoice__c ';
            query += 'WHERE CreatedDate >= ' + dateStart + ' AND CreatedDate <= ' + dateEnd + ' AND blng__InvoiceRunCreatedBy__r.Name in ' + queryRunName;

            System.debug('========================== CV_InvoiceService recaculateNumbering query: ' + query);

            Integer index = 1;
            for (blng__Invoice__c invoice : (List<blng__Invoice__c>)Database.query(query)) {

                invoice.Numero_Facturation_Cerbavet__c = CV_InvoiceService.INVOICEPREFIX_BY_TYPES.get(invoiceType) + '-' + currentDateFormatted + '-' + String.valueOf(index).leftPad(4, '0');
                invoicesToUpdate.add(invoice);
                index++;
            }
        }

        System.debug('========================== CV_InvoiceService recaculateNumbering invoicesToUpdate: ' + invoicesToUpdate);
        System.debug('========================== CV_InvoiceService recaculateNumbering invoicesToUpdate#: ' + invoicesToUpdate.size());
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }


    public static String getInvoiceType(String runName) {

        String invoiceType = 'Inconnu';

        switch on runName {
            when 'Cerbavet Clinics Monthly', 'Cerbavet Proprio', 'Cerbavet Proprio2', 'Cerbavet Clinics Monthly Adhoc' {
                invoiceType = 'Cerbavet';
            }

            when 'Cerbavet Clinics Monthly Suisse', 'Cerbavet Proprio Suisse', 'Cerbavet Clinics Monthly Suisse Adhoc', 'Cerbavet Proprio Suisse2' {
                invoiceType = 'Cerbavet Suisse';
            }
            when 'Cerbavet College' {
                invoiceType = 'Cerbavet College';
            }
        }

        return invoiceType;

    }

    private static String getRunNameQueryString(String invoiceType) {

        String runNameQueryString;

        switch on invoiceType {
            when 'Cerbavet' {
                runNameQueryString = '(\'Cerbavet Clinics Monthly\', \'Cerbavet Proprio\', \'Cerbavet Proprio2\', \'Cerbavet Clinics Monthly Adhoc\')';
            }

            when 'Cerbavet Suisse' {
                runNameQueryString = '(\'Cerbavet Clinics Monthly Suisse\', \'Cerbavet Proprio Suisse\', \'Cerbavet Clinics Monthly Suisse Adhoc\', \'Cerbavet Proprio Suisse2\')';
            }
            when 'Cerbavet College' {
                runNameQueryString = '(\'Cerbavet College\')';
            }
        }


        return runNameQueryString;

    }

}