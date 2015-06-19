SpreeSimpleTaxByZip
===================

This is a quick and dirty way to have tax rates within a state be applied by zip code.  There is currently no front end on it so after you create your tax rates, you'll need to use rails console to add the comma separated zip code list to the tax rate.

Installation
------------

Add spree_simple_tax_by_zip to your Gemfile:

```ruby
gem 'spree_simple_tax_by_zip'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_simple_tax_by_zip:install
```

Testing
-------

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_simple_tax_by_zip/factories'
```

Copyright (c) 2015 [name of extension creator], released under the New BSD License
