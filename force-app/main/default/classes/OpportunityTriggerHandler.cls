/**
 * OpportunityTriggerHandler
 * 
 * A consolidated handler class for all Opportunity trigger operations.
 * This class extends the TriggerHandler framework to provide a structured approach
 * to handling Opportunity events and enforcing business rules.
 * 
 * The handler combines logic from both OpportunityTrigger and AnotherOpportunityTrigger,
 * ensuring all business requirements are met in a unified, maintainable structure.
 */
public class OpportunityTriggerHandler extends TriggerHandler {
    private List<Opportunity> newOpportunities;
    private List<Opportunity> oldOpportunities;
    private Map<Id, Opportunity> newOpportunitiesMap;
    private Map<Id, Opportunity> oldOpportunitiesMap;
    
    // Static variable to prevent recursion in afterUpdate method
    private static Boolean isExecuting = false;
    
    /**
     * Constructor to initialize trigger context variables
     */
    public OpportunityTriggerHandler() {
        this.newOpportunities = (List<Opportunity>) Trigger.new;
        this.oldOpportunities = (List<Opportunity>) Trigger.old;
        this.newOpportunitiesMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOpportunitiesMap = (Map<Id, Opportunity>) Trigger.oldMap;
    }
    
    /**
     * Handle before insert operations
     * - Set default Type for new Opportunities
     */
    public override void beforeInsert() {
        setDefaultType();
    }
    
    /**
     * Handle before update operations
     * - Validate Amount is greater than 5000
     * - Set primary contact to CEO if not specified
     */
    public override void beforeUpdate() {
        validateAmount();
        setPrimaryContactCEO();
    }
    
    /**
     * Handle before delete operations
     * - Prevent deletion of closed Opportunities
     * - Prevent deletion of Closed Won Opportunities for Banking accounts
     */
    public override void beforeDelete() {
        preventDeleteClosedOpportunities();
        preventDeleteClosedWonBankingOpportunities();
    }
    
    /**
     * Handle after insert operations
     * - Create default task for follow-up
     */
    public override void afterInsert() {
        createDefaultTasks();
    }
    
    /**
     * Handle after update operations
     * - Update Description with stage change information
     */
    public override void afterUpdate() {
        if (!isExecuting) {
            updateDescriptionWithStageChange();
        }
    }
    
    /**
     * Handle after delete operations
     * - Notify opportunity owners of deletion
     */
    public override void afterDelete() {
        notifyOwnersOpportunityDeleted();
    }
    
    /**
     * Handle after undelete operations
     * - Assign primary contact with VP Sales title
     */
    public override void afterUndelete() {
        assignPrimaryContactVPSales();
    }
    
    // ===== PRIVATE METHODS =====
    
    /**
     * Sets the Type field to 'New Customer' for Opportunity records where Type is null
     * From AnotherOpportunityTrigger
     */
    private void setDefaultType() {
        for (Opportunity opp : newOpportunities) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }
    
    /**
     * Validates that the Amount field is greater than 5000 for updated Opportunities
     * From OpportunityTrigger
     */
    private void validateAmount() {
        for (Opportunity opp : newOpportunities) {
            if (opp.Amount != null && opp.Amount < 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }
    
    /**
     * Sets the Primary_Contact__c field to the Contact with Title 'CEO' for the Opportunity's Account
     * From OpportunityTrigger
     */
    private void setPrimaryContactCEO() {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.Primary_Contact__c == null && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        if (!accountIds.isEmpty()) {
            Map<Id, Contact> accountToCEOContactMap = new Map<Id, Contact>();
            for (Contact con : [SELECT Id, AccountId, FirstName, Title FROM Contact 
                               WHERE AccountId IN :accountIds AND Title = 'CEO' 
                               ORDER BY FirstName ASC]) {
                if (!accountToCEOContactMap.containsKey(con.AccountId)) {
                    accountToCEOContactMap.put(con.AccountId, con);
                }
            }
            
            for (Opportunity opp : newOpportunities) {
                if (opp.Primary_Contact__c == null && opp.AccountId != null && 
                    accountToCEOContactMap.containsKey(opp.AccountId)) {
                    opp.Primary_Contact__c = accountToCEOContactMap.get(opp.AccountId).Id;
                }
            }
        }
    }
    
    /**
     * Prevents deletion of closed Opportunities
     * From AnotherOpportunityTrigger
     */
    private void preventDeleteClosedOpportunities() {
        for (Opportunity opp : oldOpportunities) {
            if (opp.IsClosed) {
                opp.addError('Cannot delete closed opportunity');
            }
        }
    }
    
    /**
     * Prevents deletion of Closed Won Opportunities for Accounts with Industry 'Banking'
     * From OpportunityTrigger
     */
    private void preventDeleteClosedWonBankingOpportunities() {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oldOpportunities) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        if (!accountIds.isEmpty()) {
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN :accountIds]);
            
            for (Opportunity opp : oldOpportunities) {
                if (opp.StageName == 'Closed Won' && accounts.containsKey(opp.AccountId) && 
                    accounts.get(opp.AccountId).Industry == 'Banking') {
                    opp.addError('Cannot delete closed opportunity');
                }
            }
        }
    }
    
    /**
     * Creates default Task records for newly inserted Opportunities
     * From AnotherOpportunityTrigger
     */
    private void createDefaultTasks() {
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity opp : newOpportunities) {
            Task tsk = new Task(
                Subject = 'Call Primary Contact',
                WhatId = opp.Id,
                WhoId = opp.Primary_Contact__c,
                OwnerId = opp.OwnerId,
                ActivityDate = Date.today().addDays(3)
            );
            tasksToInsert.add(tsk);
        }
        
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
    
    /**
     * Updates the Description field with stage change information for updated Opportunities
     * From AnotherOpportunityTrigger
     */
    private void updateDescriptionWithStageChange() {
        isExecuting = true;
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
            if (opp.StageName != oldOpp.StageName && opp.StageName != null) {
                Opportunity oppToUpdate = new Opportunity(
                    Id = opp.Id,
                    Description = (opp.Description != null ? opp.Description : '') + 
                                 '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format()
                );
                oppsToUpdate.add(oppToUpdate);
            }
        }
        
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
        
        isExecuting = false;
    }
    
    /**
     * Sends email notifications to the owners of deleted Opportunities
     * From AnotherOpportunityTrigger
     */
    private void notifyOwnersOpportunityDeleted() {
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : oldOpportunities) {
            ownerIds.add(opp.OwnerId);
        }
        
        Map<Id, User> ownersMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : oldOpportunities) {
            if (ownersMap.containsKey(opp.OwnerId) && ownersMap.get(opp.OwnerId).Email != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {ownersMap.get(opp.OwnerId).Email};
                mail.setToAddresses(toAddresses);
                mail.setSubject('Opportunity Deleted : ' + opp.Name);
                mail.setPlainTextBody('Your Opportunity: ' + opp.Name + ' has been deleted.');
                mails.add(mail);
            }
        }
        
        if (!mails.isEmpty()) {
            try {
                Messaging.sendEmail(mails);
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Assigns primary contacts with Title 'VP Sales' to undeleted Opportunities
     * From AnotherOpportunityTrigger
     */
    private void assignPrimaryContactVPSales() {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        if (!accountIds.isEmpty()) {
            Map<Id, Contact> accountToPrimaryContactMap = new Map<Id, Contact>();
            for (Contact primaryContact : [SELECT Id, AccountId FROM Contact 
                                          WHERE Title = 'VP Sales' AND AccountId IN :accountIds]) {
                if (!accountToPrimaryContactMap.containsKey(primaryContact.AccountId)) {
                    accountToPrimaryContactMap.put(primaryContact.AccountId, primaryContact);
                }
            }
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Opportunity opp : newOpportunities) {
                if (opp.Primary_Contact__c == null && opp.AccountId != null && 
                    accountToPrimaryContactMap.containsKey(opp.AccountId)) {
                    Opportunity oppToUpdate = new Opportunity(
                        Id = opp.Id,
                        Primary_Contact__c = accountToPrimaryContactMap.get(opp.AccountId).Id
                    );
                    oppsToUpdate.add(oppToUpdate);
                }
            }
            
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
        }
    }
}