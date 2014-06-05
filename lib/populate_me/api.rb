require 'sinatra/base'
require 'populate_me/utils'
require 'json'

class PopulateMe::API < Sinatra::Base

  before do
    content_type 'application/json'
  end

  get '/:model' do
  end

  get '/:model/:id' do
    if params['form']=='true'
    end
    model_class = resolve_model_class(params[:model])
    model_instance = resolve_model_instance(model_class,params[:id])
    {'success'=>true,'data'=>model_instance.to_h}.to_json
  end

  delete '/:model/:id' do
    model_class = resolve_model_class(params[:model])
    model_instance = resolve_model_instance(model_class,params[:id])
    model_instance = model_instance.api_delete
    {'success'=>true,'message'=>'Deleted Successfully','data'=>model_instance.to_h}.to_json
  end

  not_found do
    response.headers['X-Cascade'] = 'pass'
    {'success'=>false,'message'=>'Not Found'}.to_json
  end

  error do
    {'success'=>false,'message'=>env['sinatra.error'].message}.to_json
  end

  module Helpers

    include PopulateMe::Utils

    def resolve_model_class(name)
      model_class = resolve_dasherized_class_name(name)
      halt(404) unless model_class.respond_to?(:api_get)
      model_class
    end

    def resolve_model_instance(model_class,id)
      instance = model_class.api_get(id)
      halt(404) if instance.nil?
      instance
    end

  end

  helpers Helpers

end

