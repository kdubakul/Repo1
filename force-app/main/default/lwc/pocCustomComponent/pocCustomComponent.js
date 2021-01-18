import { LightningElement, track } from 'lwc';
import findAccounts from '@salesforce/apex/Poc.findAccounts';

export default class Poc extends LightningElement {
    @track data = [];
    connectedCallback() {
        this.columns = [
            { label: 'Name', fieldName: 'Name' },
            { label: 'Account Number', fieldName: 'AccountNumber' },
            { label: 'Upload', type: 'fileUpload', fieldName: 'Id', typeAttributes: { acceptedFormats: '.jpg,.jpeg,.pdf,.png' } }
        ];
        findAccounts().then(res => { this.data = res; }).catch(err => console.error(err));
    }
    handleUploadFinished(event) {
        event.stopPropagation();
        console.log('data => ', JSON.stringify(event.detail.data));
    }
}