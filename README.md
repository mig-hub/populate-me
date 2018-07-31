Populate Me
===========

Overview
--------

`PopulateMe` is a modular system which provides an admin backend for any 
Ruby/Rack web application. It is made with Sinatra but you can code your 
frontend with any other Framework like Rails.

Table of contents
----------------

- [Overview](#overview)
- [Table of contents](#table-of-contents)
- [Documents](#documents)
  - [Schema](#schema)
  - [Relationships](#relationships)
  - [Validations](#validations)
  - [Callbacks](#callbacks)
  - [Single Documents](#single-documents)
  - [Mongo documents](#mongo-documents)
- [Admin](#admin)
  - [Polymorphism](#polymorphism)
  - [Customize Admin](#customize-admin)
- [API](#api)

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
- `:only_for` List of polymorphic type values

As you can see, most of the options are made for you to tailor the form
which `PopulateMe` will generate for you in the admin.

Available types are:

- `:string` Short text.
- `:text` Multiline text.
- `:boolean` Which is `true` or `false`.
- `:select` Dropdown list of options (records a string).

A `:list` type exists as well for nested documents, but it is not 
fully working yet.

The `field` method creates a getter and a setter for this particular field.

```ruby
blog_article.published # Returns true or false
blog_article.published = true
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

The `relationship` method creates 2 getters for this particular field,
one with the same name and one with `_first` at the end. Both are cached
so that the database is queried only once.

```ruby
blog_article.comments # Returns all the comments for this article
blog_article.comments_first # Returns the first comment for this article
```

It uses the `PopulateMe::Document::admin_find` and  
`PopulateMe::Document::admin_find_first` methods in the background, 
so default sorting order is respected.

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

Note: the current version works with the mongo driver version 2

Now let's declare a real document class which can persist on a database,
the `MongoDB` kind of document. The first thing we need to clarify is the
setup. Here is a classic setup:

```ruby
# lib/db.rb
require 'mongo'
require 'populate_me/mongo'

client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'your-database-name')

PopulateMe::Mongo.set :db, client.database

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
first_pedro = Person.collection.find({ 'firstname' => 'Pedro' }).first
mcs = Person.collection.find({ 'lastname' => /^Mc/i })
```

Although since these are methods from the driver, `first_pedro` returns a hash,
and `mcs` returns a `Mongo::Collection::View`. If you want document object, you can use
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

### Polymorphism

You can use the schema to set a Document class as polymorphic. The consequence 
is that the admin will make you choose a type before creating a new document. 
And then the form will only display the fields applicable to this polymorphic 
type. And once created, it will only show relationships applicable to its 
polymorphic type. You can do this with the `:only_for` option.

Here is an example of a document that can either be a title with a paragraph, or
a title with a set of images:

```ruby
# lib/models/box.rb

require 'populate_me/document'

class Box < PopulateMe::Document

  field :title
  field :paragraph, type: :text, only_for: 'Paragraph'
  relationship :images, only_for: 'Image slider'
  position_field

end
```

In this case, when you create a `Box` with the polymorphic type `Paragraph`, the
form will have a field for `:paragraph` but no relationship for images. And if 
you create a `Box` with the polymorphic type `Image slider`, it will be the 
opposite.

The option `:only_for` can also be an `Array`. Actually, when inspecting the 
`fields`, you'll see that even when you pass a `String`, it will be put inside 
an `Array`.

```ruby
Box.fields[:paragraph][:only_for] # => ['Paragraph']
```

A hidden field is automatically created called `:polymorphic_type`, therefore 
it is a method you can call to get or set the `:polymorphic_type`.

```ruby
box = Box.new polymorphic_type: 'Paragraph'
box.polymorphic_type # => 'Paragraph'
```

One of the information that the field contains is all the `:values` the field 
can have.

```ruby
Box.fields[:polymorphic_type][:values] # => ['Paragraph', 'Image slider']
```

They are in the order they are declared in the fields. If you want to just set 
this list yourself or any other option attached to the `:polimorphic_type` field 
you can do so with the `Document::polymorphic` class method.

```ruby
# lib/models/box.rb

require 'populate_me/document'

class Box < PopulateMe::Document

  polymorphic values: ['Image slider', 'Paragraph']
  field :title
  field :paragraph, type: :text, only_for: 'Paragraph'
  relationship :images, only_for: 'Image slider'
  position_field

end
```

If each polymorphic type has a lot of fields and/or relationships, you can use the 
`Document::only_for` class method which sets the `:only_for` option for 
everything inside the block.

```ruby
# lib/models/media.rb

require 'populate_me/document'

class Media < PopulateMe::Document
  
  field :title
  only_for 'Book' do
    field :author
    field :publisher
    relationship :chapters
  end
  only_for 'Movie' do
    field :script_writer
    field :director
    relationship :scenes
    relationship :actors
  end
  position_field

end
```

It is worth noting that this implementation of polymorphism is supposed to work 
with fixed schema databases, and therefore all fields and relationship exist for 
each document. In our case, books would still have a `#director` method. The 
difference is only cosmetic and mainly allows you to have forms that are less 
crowded in the admin.

To mitigate this, a few methods are there to help you. There is a predicate for 
knowing if a class is polymorphic.

```ruby
Media.polymorphic? # => true
```

For each document, you can inspect its polymorphic type or check if a field or 
relationship is applicable.

```ruby
book = Media.new polymorphic_type: 'Book', title: 'Hot Water Music', author: 'Charles Bukowski'
book.polymorphic_type # => 'Book'
book.field_applicable? :author # => true
book.relationship_applicable? :actors # => false
```

### Customize Admin

You can customize the admin with a few settings. 
The main ones are for adding CSS and javascript. 
There are 2 settings for this: `:custom_css_url` and `:custom_js_url`.

```ruby
# lib/admin.rb
require "populate_me/admin"

class Admin < PopulateMe::Admin

  set :custom_css_url, '/css/admin.css'
  set :custom_js_url, '/js/admin.js'

  set :root, ::File.expand_path('../..', __FILE__)

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

Inside the javascript file, you can use many functions and variables that
are under the `PopulateMe` namespace. See source code to know more about it.
Some are callbacks like `PopulateMe.custom_init_column` which allows you to 
bind events when a column was created.

```javascript
# /js/admin.js

$(function() {
  
  $('body').bind('change', 'select.special', function(event) {
    alert('Changed!');  
  });

  PopulateMe.custom_init_column = function(column) {
    $('select.special', column).css({color: 'orange'});
  }

});
```

The other thing you might want to do is adding mustache templates.
You can do this with the setting `:custom_templates_view`.

```ruby
# lib/admin.rb
require "populate_me/admin"

class Admin < PopulateMe::Admin
  
  set :custom_templates_view, :custom_templates

  # ...

end
```

Let's say we want to be able to set the size of the preview for attachments,
as opposed to the default value of 150. We would put this in the view:

```eruby
<script id="template-attachment-field-custom" type="x-tmpl-mustache">
  {{#url}}
    <img src='{{url}}{{cache_buster}}' alt='Preview' width='{{attachment_preview_width}}' />
    <button class='attachment-deleter'>x</button>
    <br />
  {{/url}}
  <input type='file' name='{{input_name}}' {{#max_size}}data-max-size='{{max_size}}'{{/max_size}} {{{build_input_atrributes}}} />
</script>
```

This is the default template except we've replace `150` with the mustache
variable `attachment_preview_width`. Everything that you set on the schema 
is available in the template, so you can set both the custom template name 
and the width variable in the hash passed to `field` when doing your schema.
The template name is the ID of the script tag.

```ruby
# /lib/blog_post.rb
require 'populate_me/document'

class BlogPost < PopulateMe::Document

  field :title
  field :image, type: :attachment, custom_template: 'template-attachment-field-custom', attachment_preview_width: 200, variations: [
    PopulateMe::Variation.new_image_magick_job(:thumb, :gif, "-resize '300x'")
  ]

  # ...

end
```


API
---

In a normal use, you most likely don't have anything to do with the `API` module.
It is just another middleware automatically mounted under `/api` on your `Admin`.
So if your `Admin` path is `/admin`, then your `API` path is `/admin/api`.

The purpose of the `API` module is to provide all the path patterns for creating,
deleting and updating documents. The interface does all the job for you. But if
you end up building your all custom interface, you probably want to [have a look 
at the implementation](lib/populate_me/api.rb).

Another aspect of the `API` is that it relies on document methods. So if you 
want to create a subclass of `Document`, make sure that you override everything
that the `API` or the `Admin` may need.

This module is derived from a Gem I did called [rack-backend-api](https://github.com/mig-hub/backend-api). It is not maintained any more since `PopulateMe` is the evolution
of this Gem.

