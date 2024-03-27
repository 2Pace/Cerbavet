@IsTest
public class HttpHexFormBuilderTest {
    static testMethod void testFormDataBuild() {
        String fileName = 'file.png';
        String fileContent = ''; //base64 encoded

        Blob formData = HttpHexFormBuilder.build()
                .writeParam('id', '123')
                .writeParam('message', 'my second paramter')
                //.writeFile('file', fileName, fileContent)
                .getFormAsBlob();

        //String expectedFormData = '----------------------------533330745817455354437071\r\nContent-Disposition: form-data; name="id";\r\n\r\n123\r\n----------------------------533330745817455354437071\r\nContent-Disposition: form-data; name="message";\r\n\r\nmy second paramter\r\n----------------------------533330745817455354437071\r\nContent-Disposition: form-data; name="file"; filename="file.png";\r\nContent-Type: image/png;\r\n\r\n\r\n----------------------------533330745817455354437071--';
        String expectedFormData = '----------------------------533330745817455354437071\r\nContent-Disposition: form-data; name="id";\r\n\r\n123\r\n----------------------------533330745817455354437071\r\nContent-Disposition: form-data; name="message";\r\n\r\nmy second paramter\r\n----------------------------533330745817455354437071--';
        System.debug('*** IMA formaData Value == '+ formData.tostring() );
        System.debug('*** IMA expectedFormData Value == '+ expectedFormData);
        System.assert(expectedFormData == formData.tostring());
    }

    /*static testMethod void testResolveMimeType() {
        Map<String, String> fileName2MimeType = new Map<String, String>{
            'file.png' => 'image/png',
            'file.jpg' => 'image/jpg',
            'file.JPEG' => 'image/jpg',
            'file.pgm' => 'image/x-portable-graymap',
            'file.ppm' => 'image/x-portable-pixmap',
            'file.pdf' => 'application/pdf'
        };

        for (String fileName : fileName2MimeType.keySet()) {
            String mimeType = HttpHexFormBuilder.resolveMimeType(fileName);
            String expectedMimetype = fileName2MimeType.get(fileName);
            System.assert(mimeType == expectedMimetype);
        }
    }*/
}