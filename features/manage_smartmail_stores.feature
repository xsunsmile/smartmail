Feature: Manage smartmail_stores
  In order to [goal]
  [stakeholder]
  wants [behaviour]
  
  Scenario: Register new smartmail_store
    Given I am on the new smartmail_store page
    When I fill in "Flow name" with "flow_name 1"
    And I fill in "Flow step" with "flow_step 1"
    And I fill in "Participants" with "participants 1"
    And I fill in "Email" with "email 1"
    And I fill in "Workitem" with "workitem 1"
    And I press "Create"
    Then I should see "flow_name 1"
    And I should see "flow_step 1"
    And I should see "participants 1"
    And I should see "email 1"
    And I should see "workitem 1"

  Scenario: Delete smartmail_store
    Given the following smartmail_stores:
      |flow_name|flow_step|participants|email|workitem|
      |flow_name 1|flow_step 1|participants 1|email 1|workitem 1|
      |flow_name 2|flow_step 2|participants 2|email 2|workitem 2|
      |flow_name 3|flow_step 3|participants 3|email 3|workitem 3|
      |flow_name 4|flow_step 4|participants 4|email 4|workitem 4|
    When I delete the 3rd smartmail_store
    Then I should see the following smartmail_stores:
      |Flow name|Flow step|Participants|Email|Workitem|
      |flow_name 1|flow_step 1|participants 1|email 1|workitem 1|
      |flow_name 2|flow_step 2|participants 2|email 2|workitem 2|
      |flow_name 4|flow_step 4|participants 4|email 4|workitem 4|
