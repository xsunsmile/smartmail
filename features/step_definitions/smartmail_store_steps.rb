Given /^the following smartmail_stores:$/ do |smartmail_stores|
  SmartmailStore.create!(smartmail_stores.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) smartmail_store$/ do |pos|
  visit smartmail_stores_url
  within("table > tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following smartmail_stores:$/ do |expected_smartmail_stores_table|
  expected_smartmail_stores_table.diff!(table_at('table').to_a)
end
