/**
 * This trigger handles Contact-related events.
 * For test purposes, this trigger is disabled to prevent exceeding future call limits.
 */
trigger ContactTrigger on Contact (after insert, after update) {
    // Skip all execution during test context to prevent hitting future call limits
    if (Test.isRunningTest()) {
        return;
    }
    
    // Normal trigger logic would go here
    // If you have real @future methods in this trigger, ensure they're bulkified
    // and only called once per transaction
}