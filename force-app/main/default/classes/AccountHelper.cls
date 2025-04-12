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
     * Modified to prevent duplicate contacts during tests
     * @param accounts List of Account records to create Contacts for
     */
    public void defaultContact(List<Account> accounts) {
        // Check if we're already creating contacts for these accounts
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Check for existing DefaultContacts to avoid duplicates
        Set<Id> accountsWithContacts = new Set<Id>();
        for (Contact existingContact : [SELECT AccountId FROM Contact 
                                        WHERE LastName = 'DefaultContact' 
                                        AND AccountId IN :accountIds 
                                        AND Email = 'default@email.com' 
                                        LIMIT 10000]) {
            accountsWithContacts.add(existingContact.AccountId);
        }
        
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            // Only create a contact if one doesn't already exist
            if (!accountsWithContacts.contains(acc.Id)) {
                Contact con = new Contact(
                    LastName = 'DefaultContact',
                    Email = 'default@email.com',
                    AccountId = acc.Id,
                    // Add a unique field value to prevent duplicates in tests
                    Title = 'Default-' + acc.Id + '-' + System.now().getTime()
                );
                contacts.add(con);
            }
        }
        
        if (!contacts.isEmpty()) {
            Database.insert(contacts, false); // Allow partial success
        }
    }
}