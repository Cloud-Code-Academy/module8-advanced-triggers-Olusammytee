/**
 * OpportunityTrigger
 * 
 * This is the unified trigger for all Opportunity operations.
 * It uses the OpportunityTriggerHandler class to handle all business logic,
 * following Salesforce trigger best practices.
 */
trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    // Instantiate and run the handler
    new OpportunityTriggerHandler().run();
}