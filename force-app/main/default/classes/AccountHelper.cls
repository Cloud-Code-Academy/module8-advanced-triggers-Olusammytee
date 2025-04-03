public with sharing class AccountHelper {
    
    /**
     * Sets the Type field to 'Prospect' for Account records where Type is null
     * @param objects List of Account records to process (as SObject to maintain original method signature)
     */
    public void setTypeProspect(List<SObject> objects){
        for (SObject obj : objects) {
            Account acc = (Account)obj;
            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }
        }
    }

    /**
     * Copies the shipping address fields to the corresponding billing address fields
     * @param accounts List of Account records to process
     */
    public void addressCopy(List<Account> accounts){
        for (Account acc : accounts) {
            if (acc.ShippingStreet != null) {
                acc.BillingStreet = acc.ShippingStreet;
            }
            if (acc.ShippingCity != null) {
                acc.BillingCity = acc.ShippingCity;
            }
            if (acc.ShippingState != null) {
                acc.BillingState = acc.ShippingState;
            }
            if (acc.ShippingPostalCode != null) {
                acc.BillingPostalCode = acc.ShippingPostalCode;
            }
            if (acc.ShippingCountry != null) {
                acc.BillingCountry = acc.ShippingCountry;
            }
        }
    }

    /**
     * Sets the Rating field to 'Hot' for Account records if Phone, Website, and Fax are all filled
     * @param accounts List of Account records to process
     */
    public void setRating(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
                acc.Rating = 'Hot';
            }
        }
    }

    /**
     * Creates default Contact records for each Account in the list
     * @param accounts List of Account records to create Contacts for
     */
    public void defaultContact(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            Contact con = new Contact(
                LastName = 'DefaultContact',
                Email = 'default@email.com',
                AccountId = acc.Id
            );
            contacts.add(con);
        }
        if (!contacts.isEmpty()) {
            insert contacts;
        }
    }
}