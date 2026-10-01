puts "=== Seeding Database ==="

if Event.count.zero?
  success = BillettoApi::IngestEvents.call
  
  if success
    puts "Success! #{Event.count} events have been safely saved to the database."
  else
    puts "Error! Failed to fetch data from the API. Please check your .env file credentials."
  end
else
  puts "Database already contains #{Event.count} events. Skipping......"
end

puts "=== Seeding Completed ==="
