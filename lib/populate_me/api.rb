require 'sinatra/base'
require 'populate_me/utils'
require 'populate_me/version'
require 'json'

class PopulateMe::API < Sinatra::Base

  use Rack::MethodOverride

  set :show_exceptions, false

  before do
    content_type 'application/json'
  end

  after do
    redirect(params['_destination']) unless params['_destination'].nil?
  end

  get '/version' do
    status 200
    {'success'=>true, 'version'=>PopulateMe::VERSION}.to_json
  end

  get '/:model' do
  end

  post '/:model' do
    model_class = resolve_model_class(params[:model])
    model_instance = model_class.new.set_from_hash(params[:data]||{})
    model_instance.save
    status 201
    {'success'=>true,'message'=>'Created Successfully','data'=>model_instance.to_h}.to_json
  end

  get '/:model/:id' do
    # if params['form']=='true'
    # end
    model_class = resolve_model_class(params[:model])
    model_instance = resolve_model_instance(model_class,params[:id])
    {'success'=>true,'data'=>model_instance.to_h}.to_json
  end

  put '/:model/:id' do
    model_class = resolve_model_class(params[:model])
    model_instance = resolve_model_instance(model_class,params[:id])
    model_instance.set_from_hash(params[:data])
    model_instance.save
    {'success'=>true,'message'=>'Updated Successfully','data'=>model_instance.to_h}.to_json
  end

  delete '/:model/:id' do
    model_class = resolve_model_class(params[:model])
    model_instance = resolve_model_instance(model_class,params[:id])
    model_instance.delete
    {'success'=>true,'message'=>'Deleted Successfully','data'=>model_instance.to_h}.to_json
  end

  not_found do
    response.headers['X-Cascade'] = 'pass'
    {'success'=>false,'message'=>'Not Found'}.to_json
  end

  error do
    puts
    puts env['sinatra.error'].inspect
    puts
    {'success'=>false,'message'=>env['sinatra.error'].message}.to_json
  end

  module Helpers

    include PopulateMe::Utils

    def resolve_model_class(name)
      model_class = resolve_dasherized_class_name(name) rescue nil
      halt(404) unless model_class.respond_to?(:[])
      model_class
    end

    def resolve_model_instance(model_class,id)
      instance = model_class[id]
      halt(404) if instance.nil?
      instance
    end

  end

  helpers Helpers

end
