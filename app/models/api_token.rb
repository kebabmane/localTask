class ApiToken < ApplicationRecord
  belongs_to :user
  has_one :agent, dependent: :nullify

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  attr_accessor :raw_token

  scope :active, -> { where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.authenticate(token)
    return nil if token.blank?
    prefix = token[0..7]
    api_token = active.find_by(prefix: prefix)
    return nil unless api_token
    return nil unless BCrypt::Password.new(api_token.token_digest) == token
    api_token.touch(:last_used_at)
    api_token
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  private

  def generate_token
    self.raw_token = SecureRandom.base58(48)
    self.prefix = raw_token[0..7]
    self.token_digest = BCrypt::Password.create(raw_token)
  end
end
