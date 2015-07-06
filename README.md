Populate Me
===========

Overview
--------

Warning: This is a work in process so this is why no gem is currently released with this code. If you install the Gem, you would have the version of the branch called `ground-zero`.

`PopulateMe` is a modular system which provides an admin backend for any Ruby/Rack web application.
It is made with Sinatra but you can code your frontend with any other Framework like Rails.

Table of contents
----------------

- [Overview](#overview)
- [Table of contents](#table-of-contents)
- [Documents](#documents)
  - [Schema](#schema)
  - [Validations](#validations)
  - [Relationships](#relationships)
  - [Callbacks](#callbacks)
  - [Mongo documents](#mongo-documents)
- [Admin](#admin)
- [API](#api)
- [Utils](#utils)

Documents
---------

The `Document` class is a prototype. It contains all the code that is
not specific to a database system. When using this class, documents are
just kept in memory and therefore are lost when you restart the app.

Obviously, in a real application, you would not use this class, but
a persistent one instead. But since the purpose is to have a common 
interface for any database system, then the following examples are 
written using the basic `Document` class.

For the moment, `PopulateMe` only ships with a [MongoDB](#mongo-documents) document, but we hope there will be others in the future, including some for SQL databases.

### Schema

Here is an example of a document class:

``` ruby
require 'populate_me/document'

class BlogArticle < PopulateMe::Document
  
  field :title, default: 'New blog article', required: true
  field :content, type: :text
  field :created_on, type: :datetime, default: proc{Time.now}
  field :published, type: :boolean

  sort_by :created_on, :desc

end
```

Quite common so far. 
The `field` method allows you to record anything about the field 
itself, but here are the keys used by `PopulateMe`:

- `:type` Defines the type of field (please find the list of types below).
- `:form_field` Set to `false` if you do not want this field in the default form.
- `:label` What the label in the form says (defaults to a human-friendly version of the field name)
- `:wrap` Set it to false if you do not want the form field to be wrapped in a `div` with a label.
- `:default` Either a default value or a `proc` to run to get the default value.
- `:required` Set to true if you want the field to be marked as required in the form.

As you can see, most of the options are made for you to tailor the form
which `PopulateMe` will generate for you in the admin.

Available types are:

- `:string` Short text.
- `:text` Multiline text.
- `:boolean` Which is `true` or `false`.
- `:list` List of nested documents.
- `:select` Dropdown list of options (records a string).

### Validations

In its simplest form, validations are done by overriding the `#validate` method and declaring errors with the `#error_on` method.

``` ruby
class Person < PopulateMe::Document
  
  field :name

  def validate
    error_on(:name, 'Cannot be fake') if self.name=='John Doe'
  end

end
```

If you don't use the `PopulateMe` interface and create a document
programmatically, here is what it could look like:

``` ruby
person = Person.new(name: 'John Doe')
person.new? # returns true
person.save # fails
person.valid? # returns false
person.errors # returns { name: ['Cannot be fake'] }
```

### Relationships

In its simplest form, when using the modules convention, relationships
can be declared this way:

``` ruby
class BlogArticle < PopulateMe::Document
  
  field :title

  relationship :comments

end

class BlogArticle::Comment < PopulateMe::Document

  field :author
  field :blog_article_id, type: :hidden
  position_field scope: :blog_article_id

end
```

### Callbacks

### Mongo Documents

Admin
-----

A basic admin would look like this:

``` ruby
# lib/admin.rb
require "populate_me/admin"

class Admin < PopulateMe::Admin
  # Since we are in lib we use this to move
  # the root one level up.
  # Not mandatory but useful if you plan to have
  # custom views in the main views folder
  set :root, ::File.expand_path('../..', __FILE__)
  # Only if you use Rack::Cerberus for authentication
  # you can pass the settings
  set :cerberus, {company_name: 'Nintendo'}
  # Build menu and sub-menus
  set :menu, [ 
    ['Settings', '/admin/form/settings/unique'],
    ['Articles', '/admin/list/article'],
    ['Staff', [
      ['Designers', '/admin/list/staff-member?filter[job]=Designer'],
      ['Developers', '/admin/list/staff-member?filter[job]=Developer'],
    ]]
  ]
end
```

So the main thing you need is to define your menu. Then mount it in
your `config.ru` whereever you want.

``` ruby
# config.ru
require 'admin'

map '/admin' do
  run Admin
end
```

API
---

Utils
-----

The `Utils` module is quite similar to its counterpart in `Rack`.
It gathers methods that are used in many places in the project.
Many of them are similar to methods you would have in `Active::Support`
but without monkey patching.

Anyway it is a good idea to mix it to your helpers, some of the
methods are even added just for this purpose. Also it has `Rack::Utils`
included so you don't need to put both.

Here is how you would have it in a `Sinatra` frontend:

``` ruby
require 'sinatra/base'
require 'populate_me/utils'

class Main < Sinatra::Base

  # Your frontend code...

  helpers do
    include PopulateMe::Utils
    # Your other helpers...
  end

end
```

Here is a list of the available methods:



