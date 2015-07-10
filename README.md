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
  - [Single Documents](#single-documents)
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

```ruby
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

```ruby
class Person < PopulateMe::Document
  
  field :name

  def validate
    error_on(:name, 'Cannot be fake') if self.name=='John Doe'
  end

end
```

If you don't use the `PopulateMe` interface and create a document
programmatically, here is what it could look like:

```ruby
person = Person.new(name: 'John Doe')
person.new? # returns true
person.save # fails
person.valid? # returns false
person.errors # returns { name: ['Cannot be fake'] }
```

### Relationships

In its simplest form, when using the modules convention, relationships
can be declared this way:

```ruby
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

There are some classic hooks which trigger the callbacks you declare.
Here is a basic example:

```ruby
require 'populate_me/document'

class Person < PopulateMe::Document
  
  field :firstname
  field :lastname
  field :fullname, form_field: false

  before :save do
    self.fullname = "#{self.firstname} #{self.lastname}"
  end

  after :delete, :goodbye

  def goodbye
    puts "So long and thanks for all the fish"
  end

end
```

First you can note that the field option `form_field: false` makes it a field
that does not appear in the form. This is generally the case for fields that 
are generated from other fields.

Anyway, here we define a callback which `PopulateMe` runs each time a document
is saved. And with the second one, you can see that we can pass the name of
a method instead of a block.

The list of hooks is quite common but here it is as a reminder:

- `before :validation`
- `after :validation`
- `before :create`
- `after :create`
- `before :update`
- `after :update`
- `before :save` (both create or update)
- `after :save` (both create or update)
- `before :delete`
- `after :delete`

Now you can register many callbacks for the same hook. They will be chained in
the order you register them. However, if for any reason you need to register a
callback and make sure it runs before the others, you can add `prepend: true`.

```ruby
before :save, prepend: true do
  puts 'Shotgun !!!'
end
```

If you want to go even further and create your own hooks, this is very easy.
You can create a hook like this:

```ruby
document.exec_callback(:my_hook)
```

And you would then register a callback like this:

```ruby
register_callback :my_hook do
  # Do something...
end
```

You can use `before` and `after` as well. In fact this:

```ruby
after :lunch do
  # Do something...
end
```

Is equivalent to:

```ruby
register_callback :after_lunch do
  # Do something...
end
```

### Single Documents

Sometimes you want a collection with only one document, like for recording
settings for example. In this case you can use the `::is_unique` class method.

```ruby
require 'populate_me/document'

class GeneralWebsiteSettings < PopulateMe::Document
  field :main_meta_title
  field :main_meta_description
  field :google_analytics_ref
end

GeneralWebsiteSettings.is_unique
```

It just creates the document if it does not exist yet with the ID `unique`.
If you want a different ID, you can pass it as an argument.

Just make sure that if you have fields with `required: true`, they also have
a `:default` value. Otherwise the creation of the document will fail because it
is not `self.valid?`.

### Mongo Documents

Now let's declare a real document class which can persist on a database,
the `MongoDB` kind of document. The first thing we need to clarify is the
setup. Here is a classic setup:

```ruby
# lib/db.rb
require 'mongo'
require 'populate_me/mongo'

connection = Mongo::Connection.new

PopulateMe::Mongo.set :db, connection['your-database-name']

require 'person'
```

Then the document is pretty much the same as the prototype except that it
subclasses `PopulateMe::Mongo` instead.

```ruby
# lib/person.rb
require 'populate_me/mongo'

class Person < PopulateMe::Mongo
  field :firstname
  field :lastname
end
```

As you can see in setup, you can define inheritable settings on 
`PopulateMe::Mongo`, meaning that any subclass after this will have the `:db`
and you can set it only once.

Nevertheless it is obviously possible to set a different `:db` for each class.

```ruby
# lib/person.rb
require 'populate_me/mongo'

class Person < PopulateMe::Mongo

  set :db, $my_db

  field :firstname
  field :lastname

end
```

This is particularly useful if you keep a type of documents in a different 
location for example. Otherwise it is more convenient to set it once 
and for all.

You can also set `:collection_name`, but in most cases you would let `PopulateMe`
defaults it to the dasherized class name. So `BlogArticle::Comment` would be
in the collection called `blog-article--comment`.

Whatever you choose, you will have access to the collection object with the
`::collection` class method. Which allows you to do anything the driver does.

```ruby
first_pedro = Person.collection.find_one({ 'firstname' => 'Pedro' })
mcs = Person.collection.find({ 'lastname' => /^Mc/i })
```

Although since these are methods from the driver, `first_pedro` returns a hash,
and `mcs` returns a `Mongo::Cursor`. If you want document object, you can use
the `::cast` class method which takes a block in the class context/scope and
casts either a single hash into a full featured document, or casts the items of
an array (or anything which responds to `:map`).

```ruby
first_pedro = Person.cast{ collection.find_one({ 'firstname' => 'Pedro' }) }
mcs = Person.cast{ collection.find({ 'lastname' => /^Mc/i }) }
first_pedro.class # returns Person
mcs[0].class # returns Person
```

Admin
-----

A basic admin would look like this:

```ruby
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

```ruby
# config.ru
require 'admin'

map '/admin' do
  run Admin
end
```

Most of the URLs in your menu will probably be for the admin itself and use
the admin URL patterns, but this is not mandatory. A link to an external page 
would load in a new tab. Whereas admin URLs create columns in the `PopulateMe`
user interface. Many things are possible with these patterns but here are 
the main ones:

- `/:path_to_admin/list/:dasherized_document_class` This gives you the list of
documents from the desired class. They are ordered as specified by `sort_by`.
You can also filter like in the example to get only specific documents.
- `:path_to_admin/form/:dasherized_document_class/:id` You would rarely use this
one which directly opens the form of a specific document, since all this is 
generally accessed from the list page. It doesn't need to be coded. The only is
probably for [single documents](#single-documents) because they are not part of
a list. The ID would then be litterally `unique`, or whatever ID you declared
instead.

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

```ruby
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

- `#blank?(string)` Tells you if the string is blank or not.
- `#pluralize(string)` Pluralize simple cases. Just override when necessary.
- `#dasherize_class_name(string)` It is the convention used by `PopulateMe` in URLs. Module separator is a double dash. So `BlogArticle::Comment` becomes `blog-article--comment`. Also we use a straight forward method does not gather accronyms. e.g. `net--f-t-p`.
- `#undasherize_class_name(string)` Basically the opposite.
- `#resolve_class_name(string)` It takes the class name as a string and returns the class.
- `#resolve_dasherized_class_name(string)` Same except that it takes the dasherized version of the class name as an argument and returns the class.
- `#guess_related_class_name(parent_class, string)` It is mainly used for guessing the class name of a children class with a plural name. So `guess_related_class_name(BlogArticle, :comments)` will return `'BlogArticle::Comment'`.
- `#get_value(object,context=Kernel)` It is used either take a value directly, or if the object is a `Proc`, it runs it to get the value. If the object is a symbol, it calls the method of the same name on the context. This is what `PopulateMe` uses for getting the default on fields. In this case the context is obviously `self`, the document itself.
- `#deep_copy(object)` This makes a deeper copy of an object, since `dup` does not duplicate nested objects in a hash for example. It uses a simple marshal/unmarshal mechanism. 
- `#ensure_key(hash,key,default_value)` If the hash does not have the key, it sets it with the default value.
- `#slugify(string)` This makes the strings ready to be used as a slug in a URL. It removes the accents, replaces a lot of separators with dashes and escapes it. By default it forces the output to be lowercase, but if you pass `false` as a second argument, it will not change the case of letters.
- `#each_stub(nested_object) {|object,key_or_index,value| ... }` It is used to run something on all the nested stubs of an array or a hash. The second argument of the block is either a key if the object is a hash, or an index if the object is an array.
- `#automatic_typecast(string)` It tries to change a string value received by an HTML for or a CSV file into an object when it can. So far it recognize simple things like `true`, `false`. And an empty string is always `nil`.
- `#generate_random_id(size)` Like the name suggest, it generates a random string of only letters and numbers. If you  don't provide a size, it defaults to 16.
- `#nl2br(string)` The classic `nl2br` which makes sure return lines are turned into `<br>` tags. You can use the second argument if you want to specify what the replacement tag should be. Just in case you want closing tags. 
- `#complete_link(string)` This just makes sure that a link is complete. Very often people tend to enter a URL like `www.google.com` which is a controvertial `href` for some browsers, so it changes it to `//www.google.com`.
- `#external_link?(string)` This tells you if a link is pointing to the current site or an external one. This is useful when you want to create a link tag and want to decide if target is '_blank' or '_self'.
- `#automatic_html(string)` This automatically does `nl2br` and links recognizable things like email addresses and URLs. Not as good as markdown, but it is quite useful, should it be only for turning an email into a link.
- `#truncate(string, size)` It truncates a string like what you have in blog summaries. It automatically removes tags and line breaks. The length is 320 by default. When the original string was longer, it puts an ellipsis at the end which can be replaced by whatever you put as a 3rd argument. e.g. `'...and more'`.
- `#display_price(int)` It changes a price in cents/pence into a formated string like : `49,425.40`.
- `#parse_price(string)` It does the opposite and parses a string in order to return a price in cents/pence.
- `#branded_filename(path,prefix)` It takes the path to a file and add the prefix and a dash before the file name. By default, the prefix is `PopulateMe`.
- `#filename_variation(path,variation,ext)` For example you have a file `/path/to/image.jpg` and you want to create its `thumbnail` in `png`, you can create the thumnail path with `filename_variation(path, :thumbnail, :png)` and it will return `/path/to/image.thumbnail.png`.

