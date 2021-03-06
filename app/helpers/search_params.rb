# This model is just a convenience wrapper for the relevant search query params, for use with FormHelper in the view.
class SearchParams
  include ActiveModel::Model

  attr_accessor :q, :sort, :direction

  def initialize(attributes = {})
    attributes.keys.each { |name| class_eval { attr_accessor name } } # Add any additional query attributes to the model
    super(attributes)
  end
end
