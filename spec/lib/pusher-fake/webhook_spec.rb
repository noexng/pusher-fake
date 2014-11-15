require "spec_helper"

describe PusherFake::Webhook, ".trigger" do
  subject { PusherFake::Webhook }

  let(:data)          { { channel: "name" } }
  let(:http)          { double(:http, post: true) }
  let(:name)          { "channel_occupied" }
  let(:digest)        { double(:digest) }
  let(:payload)       { MultiJson.dump({ events: [data.merge(name: name)], time_ms: Time.now.to_i }) }
  let(:webhooks)      { ["url"] }
  let(:signature)     { "signature" }
  let(:configuration) { double(:configuration, key: "key", secret: "secret", webhooks: webhooks) }

  before do
    allow(OpenSSL::HMAC).to receive(:hexdigest).and_return(signature)
    allow(OpenSSL::Digest::SHA256).to receive(:new).and_return(digest)
    allow(EventMachine::HttpRequest).to receive(:new).and_return(http)
    allow(PusherFake).to receive(:log)
    allow(PusherFake).to receive(:configuration).and_return(configuration)
  end

  it "generates a signature" do
    subject.trigger(name, data)

    expect(OpenSSL::HMAC).to have_received(:hexdigest)
      .with(digest, configuration.secret, payload)
  end

  it "creates a HTTP request for each webhook URL" do
    subject.trigger(name, data)

    expect(EventMachine::HttpRequest).to have_received(:new).with(webhooks.first)
  end

  it "posts the payload to the webhook URL" do
    subject.trigger(name, data)

    expect(http).to have_received(:post).with(
      body: payload,
      head: {
        "Content-Type"       => "application/json",
        "X-Pusher-Key"       => configuration.key,
        "X-Pusher-Signature" => signature
      }
    )
  end

  it "logs sending the hook" do
    subject.trigger(name, data)

    expect(PusherFake).to have_received(:log).with("HOOK: #{payload}")
  end
end
