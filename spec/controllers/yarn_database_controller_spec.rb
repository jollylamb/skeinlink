require 'rails_helper'

RSpec.describe YarnDatabaseController do
  describe '#index' do
    context 'when user is not authenticated' do
      before { get :index }
      it_behaves_like 'redirects to login'
    end

    context 'when user is authenticated' do
      let(:user) { create :user }
      let(:yarn_product) { create :yarn_product }

      before do
        sign_in user
        get :index
      end

      it_behaves_like 'successful response'

      it 'returns yarn products' do
        expect(assigns[:yarn_products]).to include yarn_product
      end
    end
  end

  describe '#create' do
    context 'when user is not authenticated' do
      before { post :create }
      it_behaves_like 'redirects to login'
    end

    context 'when user is authenticated' do
      let(:yarn_product_attrs) do
        build(:yarn_product, :with_optional_fields)
          .attributes
          .slice('name', 'skein_gram_weight', 'skein_yards', 'fiber_type_name', 'craft_yarn_council_weight',
                 'description', 'referral_link', 'referral_partner', 'weight_id')
      end
      let(:sample_image_data) { fixture_file_upload file_fixture('images/jpg-test-1.jpg') }

      before do
        sign_in user
        allow(ImageAttachmentService).to receive(:call)
        post :create, params: {
          yarn_product: yarn_product_attrs.merge({image: sample_image_data}),
          fiber_content_tags: ['Wool', 'Spaghetti'].to_json
        }
      end

      context 'when user is not authorized to create a yarn product' do
        let(:user) { create :user }

        it_behaves_like 'displays maintainer flash'
        it_behaves_like 'redirects to root path'
      end

      context 'when user is authorized to create a yarn product' do
        let(:user) { create :user, :maintainer }
        let(:yarn_product) { YarnProduct.find_by(name: yarn_product_attrs['name']) }

        it 'redirects to new yarn product' do
          expect(response).to redirect_to yarn_product_path(yarn_product)
        end

        it 'creates the new yarn product with the expected attributes' do
          expect(yarn_product.attributes).to include(yarn_product_attrs)
          expect(yarn_product.created_by).to eq user.id
        end

        it 'attaches the uploaded image' do
          expect(ImageAttachmentService).to have_received(:call).with(hash_including(
            images: kind_of(ActionDispatch::Http::UploadedFile), record: kind_of(YarnProduct)
          ))
        end

        it 'sets the expected fiber content tags' do
          expect(yarn_product.fiber_content.map(&:name)).to include 'Wool'
        end

        it 'does not set unknown fiber content tags' do
          expect(yarn_product.fiber_content.map(&:name)).to_not include 'Spaghetti'
        end
      end
    end
  end
end
