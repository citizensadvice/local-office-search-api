# frozen_string_literal: true

RSpec.shared_context "with episerver credentials" do
  # rubocop:disable RSpec/VariableName - has to be cased like this for RSwag!
  let(:Authorization) do
    # rubocop:enable RSpec/VariableName
    ActionController::HttpAuthentication::Basic.encode_credentials(ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_USER"),
                                                                   ENV.fetch("LOCAL_OFFICE_SEARCH_EPISERVER_PASSWORD"))
  end
end
