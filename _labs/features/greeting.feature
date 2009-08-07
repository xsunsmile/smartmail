
Feature: greeter says hello
  
  Some descriptions.
  
  Scenario: greeter says hello
    Given a greeter
    When i send it the hello message
    Then it should say "Hello Cucumber!"
