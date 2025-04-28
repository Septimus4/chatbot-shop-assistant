Setup:
Configure env with OPENAIKEY="your key"

Load data from ext source:
rails c
FetchProductsJob.perform_now

I used sqlite for database, I worked probably too much on the model/database design.