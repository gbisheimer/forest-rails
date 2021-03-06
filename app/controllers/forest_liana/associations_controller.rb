module ForestLiana
  class AssociationsController < ForestLiana::ApplicationController

    before_filter :find_resource
    before_filter :find_association

    def index
      getter = HasManyGetter.new(@resource, @association, params)
      getter.perform

      render serializer: nil, json: serialize_models(getter.records,
                                                     include: includes,
                                                     count: getter.count,
                                                     params: params)
    end

    private

    def find_resource
      @resource = SchemaUtils.find_model_from_table_name(params[:collection])

      if @resource.nil? || !@resource.ancestors.include?(ActiveRecord::Base)
        render serializer: nil, json: {status: 404}, status: :not_found
      end
    end

    def find_association
      # Rails 3 wants a :sym argument.
      @association = @resource.reflect_on_association(
        params[:association_name].try(:to_sym))

      # Only accept "many" associations
      if @association.nil? ||
        [:belongs_to, :has_one].include?(@association.macro)
        render serializer: nil, json: {status: 404}, status: :not_found
      end
    end

    def resource_params
      ResourceDeserializer.new(@resource, params[:resource]).perform
    end

    def includes
      @association.klass
        .reflect_on_all_associations
        .select do |a|
          [:belongs_to, :has_and_belongs_to_many].include?(a.macro) &&
            !a.options[:polymorphic]
        end
        .map {|a| a.name.to_s }
    end

  end
end
