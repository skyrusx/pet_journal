class LegalController < ApplicationController
  layout "legal"

  def privacy
    assign_common(:privacy_policy)
  end

  def personal_data_consent
    assign_common(:personal_data_consent)
  end

  private

  def assign_common(document_key)
    @legal_document = LegalDocuments.fetch(document_key)
    @operator_name = LegalOperatorConfiguration.name
    @operator_email = LegalOperatorConfiguration.email
    @operator_details = LegalOperatorConfiguration.details
  end
end
