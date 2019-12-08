# Kisi ActiveJob Google PubSub adapter

Coding challenge from Kisi.


## Challenge

Taken from [this gist](https://gist.github.com/ce07c3/e8048fc468eef503cbc78a21855aa139).

Build a background job system to use with Rails based on Google Pub Sub

The idea is to build a background job system that is compatible with the ActiveJob interface of Rails and allows Rails developers to easily enqueue jobs to a Google Pub Sub backend. The details:

- Transparent enqueueing with ActiveJob to Google Pub Sub
- Background workers dequeue job params and execute the corresponding jobs
- If a job fails, it should be retried at most two times at least five minutes apart 
  - Three tries in total
  - If the second retry fails, enqueue the job to a morgue queue
- Use ActiveSupport::Instrumentation to collect simple metrics
  - Jobs performed (total count)
  - Jobs performed (total duration)
- Deliverable: Github repository with Rails project including CLI command to start the background job queue
- Inspiration: https://cloud.google.com/ruby/getting-started/using-pub-sub (note: solution is lacking a mature OO approach and keeps the worker inside the adapter - perhaps don’t follow this approach)

## Setup

- Clone the repo
- Install gems (`bundle install`)

## Configure

### PubSubAdapter options

The `PubSubAdapter` can be configured using a snippet like this:

```ruby
ActiveJob::PubSub::PubSubAdapter.configure do |config|
  config[:max_retries] = 3
  config[:worker_threads] = 8
  config[:ack_threads] = 4
end
```

See [`adapter.rb`](/demo/lib/pubsub_adapter/adapter.rb#L9) for all options:

```ruby
# How many times a job should be retried before it's sent to the deadletter queue
# The total number of attempts will be max_retries + 1.
max_retries: 3,
# Name of the deadletter/morgue queue
dead_letter_queue: 'deadletter',
# String prefix to add to topics (queues)
queue_prefix: 'activejob-',
# String prefix to add to subscription names
subscription_prefix: 'activejob-subscription-',
# The number of threads used to handle received messages
worker_threads: 8,
# The number of threads to handle acks and nacks
ack_threads: 4,
```

### PubSub emulator

The fastest way to try this project out is to use the PubSub emulator:

```
gcloud components install pubsub-emulator
gcloud components update
# See if it works, kill with ctrl-C
gcloud beta emulators pubsub start --project=fake-project-id
```

Documentation: https://cloud.google.com/pubsub/docs/emulator

### PubSub

If you want to use Google PubSub, there are [many
ways](https://googleapis.dev/ruby/google-cloud-pubsub/latest/file.AUTHENTICATION.html#Project_and_Credential_Lookup)
to configure authentication credentials and project id.

I recommend using environment variables to configure the project and
credentials path:

```
export PUBSUB_PROJECT="set your project id here"
export PUBSUB_CREDENTIALS="path/to/keyfile.json"
```

To get a keyfile, see https://cloud.google.com/iam/docs/creating-managing-service-account-keys

The service account needs publish and subscribe permissions, of
course, and unless you create the subscription and topics manually it
also needs to be able to create topics and subscriptions. The `Pub/Sub
Editor` role seems to be the best fit.


## Running

### PubSub emulator

If using the emulator (see above), start it:

```
gcloud beta emulators pubsub start --project=fake-project-id
```

Make sure to set the required environment variables to configure the
emulator and the PubSub client library in each terminal you run the
emulator, the server, or the worker:

```
export PUBSUB_PROJECT=fake-project-id
`gcloud beta emulators pubsub env-init`
```

### Web server

```
rails server
```

### Job worker

If running the emulator, make sure the environment variables are set
(see above) for the worker as well.

```
rake jobs:work
```

If you want output, configure the Rails logger or add the
`jobs:to_stdout` task, which will configure the `Rails.logger` to
write to stdout:

```
rake jobs:to_stdout jobs:work
```

## Subscription

- Delivery type: pull
- Subscription expiration: ?
- Acknowledgement deadline: 10-600 seconds
- Message retention duration: ?
- Retain ack'd messages

## Inspiration

In the spirit of full disclosure; I'm
([almost](https://github.com/andrelaszlo/jho-launcher)
[completely](https://github.com/andrelaszlo/photogun)) new to Ruby, so
I read a lot of code during this project to try to get a grasp of best
practices and common Ruby/Rails patterns. Here are a few of the
documents, libraries, and snippets that I've drawn inspiration from:

- https://github.com/GoogleCloudPlatform/getting-started-ruby/blob/steps/6-task-queueing/lib/active_job/queue_adapters/pub_sub_queue_adapter.rb
- https://github.com/collectiveidea/delayed_job/blob/73bd1b50e719b336b70fcbb8dc4a37ec9b2f6f35/lib/delayed/tasks.rb
- https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-pubsub/lib/google/cloud/pubsub/received_message.rb
- https://github.com/googleapis/google-cloud-ruby/tree/master/google-cloud-pubsub
- https://github.com/rails/rails/blob/97b08334589cf15e86b5c89e13b62ac39e910d34/activejob/lib/active_job/queue_adapters/inline_adapter.rb
- https://github.com/ursm/activejob-google_cloud_pubsub
- https://www.enterpriseintegrationpatterns.com/patterns/messaging/CompetingConsumers.html
- https://www.rubydoc.info/gems/activejob
