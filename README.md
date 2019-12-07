# Kisi ActiveJob Google PubSub adapter

Coding challenge from Kisi.

[Instructions](https://gist.github.com/ce07c3/e8048fc468eef503cbc78a21855aa139)

## Challenge

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

## Subscription

- Delivery type: pull
- Subscription expiration: ?
- Acknowledgement deadline: 10-600 seconds
- Message retention duration: ?
- Retain ack'd messages

## Inspiration

- https://github.com/ursm/activejob-google_cloud_pubsub
- https://github.com/GoogleCloudPlatform/getting-started-ruby/blob/steps/6-task-queueing/lib/active_job/queue_adapters/pub_sub_queue_adapter.rb
- https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-pubsub/lib/google/cloud/pubsub/received_message.rb
- https://www.rubydoc.info/gems/activejob
- https://www.enterpriseintegrationpatterns.com/patterns/messaging/CompetingConsumers.html

## Run with local pubsub (for free!)

https://cloud.google.com/pubsub/docs/emulator

Install emulator:
```
gcloud components install pubsub-emulator
gcloud components update
# Start the emulator
gcloud beta emulators pubsub start --project=fake-project-id
```

## Configuration

See:
- https://github.com/googleapis/google-cloud-ruby/tree/master/google-cloud-pubsub
- https://googleapis.dev/ruby/google-cloud-pubsub/latest/index.html
- https://googleapis.dev/ruby/google-cloud-pubsub/latest/file.AUTHENTICATION.html
