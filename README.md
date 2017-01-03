# Pliny Librato

A [Librato](https://librato.com) metrics reporter backend for [pliny](https://github.com/interagent/pliny).


This backend will push reported metrics onto a queue, then periodically
submit them asynchronously.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "pliny-librato"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pliny-librato

## Usage

Add a new initializer `config/initializers/librato.rb`:

```ruby
Librato::Metrics.authenticate(Config.librato_email, Config.librato_key)
librato_backend = Pliny::Librato::Metrics::Backend.new(source: "myapp.production")
librato_backend.start
Pliny::Metrics.backends << librato_backend
```

Now `Pliny::Metrics` methods will build a queue and automatically send metrics
to Librato.

```ruby
Pliny::Metrics.count(:foo, 3)
Pliny::Metrics.measure(:bar) do
  # Some stuff you want to time
end
```

By default, it will send queued metrics every minute, or whenever the
queue reaches 1000 metrics. These settings can be configured on initialization.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/heroku/pliny-librato.
